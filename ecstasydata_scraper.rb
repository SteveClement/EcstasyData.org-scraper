['rubygems','open-uri','nokogiri','sequel'].each{|g| require g}

DB = Sequel.sqlite('EcstasyData_org.db')
DB.create_table! :data_table do
	primary_key :id
	Integer :pill_id
	String :pill_url
	String :pill_name
	String :other_name
	String :not_ecstasy
	Date :date_tested
	Date :date_published
	String :location
	String :state
	String :city
	String :tablet_vol
	String :tablet_diameter
	String :tablet_height
	String :substance
	String :substance_ratio_text
	String :substance_ratio
	String :ratio_percent
	String :source_name
	String :source_url
end
data_table = DB[:data_table]

us_hsh = {
	'AL'=>'Alabama',
	'AK'=>'Alaska',
	'AZ'=>'Arizona',
	'AR'=>'Arkansas',
	'CA'=>'California',
	'CO'=>'Colorado',
	'CT'=>'Connecticut',
	'DE'=>'Delaware',
	'DC'=>'District of Columbia',
	'FL'=>'Florida',
	'GA'=>'Georgia',
	'HI'=>'Hawaii',
	'ID'=>'Idaho',
	'IL'=>'Illinois',
	'Il'=>'Illinois',
	'IN'=>'Indiana',
	'IA'=>'Iowa',
	'KS'=>'Kansas',
	'KY'=>'Kentucky',
	'LA'=>'Louisiana',
	'ME'=>'Maine',
	'MD'=>'Maryland',
	'MA'=>'Massachusetts',
	'MI'=>'Michigan',
	'MN'=>'Minnesota',
	'MS'=>'Mississippi',
	'MO'=>'Missouri',
	'MT'=>'Montana',
	'NE'=>'Nebraska',
	'NV'=>'Nevada',
	'NH'=>'New Hampshire',
	'NJ'=>'New Jersey',
	'NM'=>'New Mexico',
	'NY'=>'New York',
	'NC'=>'North Carolina',
	'ND'=>'North Dakota',
	'OH'=>'Ohio',
	'OK'=>'Oklahoma',
	'OR'=>'Oregon',
	'PA'=>'Pennsylvania',
	'RI'=>'Rhode Island',
	'SC'=>'South Carolina',
	'SD'=>'South Dakota',
	'TN'=>'Tennessee',
	'TX'=>'Texas',
	'UT'=>'Utah',
	'VT'=>'Vermont',
	'VA'=>'Virginia',
	'WA'=>'Washington',
	'WV'=>'West Virginia',
	'WI'=>'Wisconsin',
	'WY'=>'Wyoming'
}

base_url = 'https://www.ecstasydata.org'
url = base_url + '/index.php?sort=DatePublishedU+desc&start=0&max=999999'
page = Nokogiri::HTML(open(url))
tr_arr = page.css('tbody tr')

tr_arr.each{|tr|
	td_arr = tr.css('td')

	pill_id = tr.css('td.Tablet img').attr('alt').text
	pill_url = base_url+'/view.php?id='+pill_id
	pill_name = td_arr[1].css('a').text
	other_name = tr.css('p.other-name').text.force_encoding("ISO-8859-1")
	not_ecstasy = tr.css('p.not-ecstasy').text
	date_tested = Time.parse(td_arr[5].text)
	date_published = Time.parse(td_arr[4].text)
	location = td_arr[6].text.strip

	state = ''
	city = ''
	us_hsh.each_pair{|abbrev, state_name|
		begin
			state_abbrev_test = location.split(',')[-1].strip
		rescue Exception => e
			state_abbrev_test = ''
		end # DONE: begin

		if state_abbrev_test===abbrev
			state = state_name
			city = location.split(',')[0].strip
		elsif state_abbrev_test==='USA'
			if location.split(',')[-2].strip===abbrev
				state = state_name
				city = location.split(',')[0].strip
			end # DONE: if location.split(',')[-2].strip===abbrev
		elsif state_abbrev_test==='Washington D.C.'
			state = 'District of Columbia'
			city = 'Washington'
		end # DONE: if state_abbrev_test===abbrev
	} # us_hsh.each_pair
	tablet_vol = td_arr[7].text.split(',')[0]

	begin
		tablet_diameter = td_arr[7].text.split(',')[1].split(' x ')[0].strip
		tablet_height = td_arr[7].text.split(',')[1].split(' x ')[1].strip
	rescue Exception => e
		tablet_diameter = ''
		tablet_height = ''
	end # DONE: begin

	source_name = td_arr[8].text
	source_url = base_url+'/'+td_arr[8].css('a').attr('href')

	substance_ratio_arr = td_arr[3].css('li').map{|li| li.text.to_f}
	substance_ratio_sum = substance_ratio_arr.inject{|sum,x| sum + x}
	td_arr[2].css('li').zip(td_arr[3].css('li')){|li_substances, li_ratios|
		substance = li_substances.text
		substance_ratio_text = li_ratios.text
		substance_ratio = substance_ratio_text.to_f
		ratio_percent = (substance_ratio/substance_ratio_sum).to_s


		p [pill_id, pill_url, pill_name, other_name, not_ecstasy, date_tested, date_published, location, state, city, tablet_vol, tablet_diameter, tablet_height, substance, substance_ratio_text, substance_ratio, ratio_percent, source_name, source_url]
		data_table.insert(
			:pill_id => pill_id,
			:pill_url => pill_url,
			:pill_name => pill_name,
			:other_name => other_name,
			:not_ecstasy => not_ecstasy,
			:date_tested => date_tested,
			:date_published => date_published,
			:location => location,
			:state => state,
			:city => city,
			:tablet_vol => tablet_vol,
			:tablet_diameter => tablet_diameter,
			:tablet_height => tablet_height,
			:substance => substance,
			:substance_ratio_text => substance_ratio_text,
			:substance_ratio => substance_ratio,
			:ratio_percent => ratio_percent,
			:source_name => source_name,
			:source_url => source_url
		) # DONE: data_table.insert
	} # DONE: td_arr[2].css('li').zip(td_arr[3].css('li'))
	p '======'
} # DONE: tr_arr.each
