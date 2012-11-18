package Caretaker;
use Dancer ':syntax';
use Template;
use Dancer::Plugin::Database;
use Net::OAuth2::Client;
use DateTime;
use DBI;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/search' => sub {
    template 'search.tt';
};

get '/add' => sub {
    template 'add.tt';
};

post '/apartment/save' => sub {

	my $dt = DateTime->now(time_zone=>'local');
	my $create_dttm = $dt->datetime();
	
	my $owner = 'http://in.linkedin.com/in/namratagaikwad';
	my $location = params->{location};
	my $bathrooms = params->{bathrooms};
	my $possession = params->{possession};
	my $area = params->{area};
	my $desc = params->{description};
	my $furnished = params->{furnishing};
	my $amount = params->{amount};
	my $type = params->{type};
	my $address = params->{address};
	my $bedrooms = params->{bedrooms};
	my $deposit = params->{deposit};
	
	my $q = "
	INSERT INTO
		basic_apartment
		(
		 	create_dttm,
		 	owner,
		 	images,
		 	location,
		 	bathrooms,
		 	possession,
		 	area,
		 	update_dttm,
		 	description,
		 	furnished,
		 	amount,
		 	type,
		 	address,
		 	bedrooms,
		 	deposit
	 	)
	 VALUES
	 	(
	 		'$create_dttm',
	 		'$owner',
	 		'dummy',
	 		ST_GeomFromText('$location', 4326),
	 		$bathrooms,
	 		'$possession',
	 		$area,
	 		'$create_dttm',
	 		'$desc',
	 		'$furnished',
	 		$amount,
	 		'$type',
	 		'$address',
	 		$bedrooms,
	 		$deposit
	 	)";

	info $q;	
	
	database->do($q);
};

get '/apartments' => sub {
	my $type = params->{type};
	my $lat = params->{lat};
	my $lng = params->{lng};
	my $radius = params->{radius};
	my $bedrooms = params->{bedrooms};
	my @budget = split(',', params->{budget});
	my $furnishing = params->{furnishing};
	my $sort_by = params->{sort_by};
	
	my $q;
	if($budget[0] == 30000) {
		$q = "SELECT id, amount, deposit, area, bedrooms, address, owner, update_dttm from basic_apartment where type = '$type' and bedrooms = $bedrooms and amount between";
	}
	else {
		$q = "SELECT id, amount, deposit, area, bedrooms, address, owner, date(update_dttm) as published, round((ST_distance(location, GeomFromText('POINT($lat $lng)', 4326), false)/1000)::numeric, 2) as distance, x(location) as dlat, y(location) as dlng from basic_apartment where type = '$type' and bedrooms = $bedrooms and amount between $budget[0] and $budget[1] and ST_DWithin(ST_Transform(location, 26986), ST_TRANSFORM(geomfromtext('POINT($lat $lng)', 4326), 26986), $radius) order by amount";
	}
	
	my $apartments = database->selectall_arrayref($q, { Slice=>{} });
	info $apartments;
	
	foreach my $rec (@$apartments) {
		foreach my $key (keys %$rec) {
			$key =~ tr/'//;
		}
	}
	
	template 'apartments.tt', { apartments => $apartments, slat => $lat, slng => $lng }, {layout => undef};
	
};

true;
