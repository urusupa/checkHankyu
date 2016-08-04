#! ruby -Ku
# encoding: utf-8

###############################################################################
# checkHankyu.rb
# in:
# out:
# 
###############################################################################

require 'rubygems'
require 'mechanize'
require 'nkf'
require 'fileutils'
require 'common'

###############################################################################
# 関数定義
###############################################################################

def getRailInfo()
	result = `wget -q -N -r -np -nH http://www.hankyu.co.jp/railinfo/ -P /home/nyctea/projects/tmp/hankyu`
	#ls|egrep -v '^railinfo$'|xargs rm -r
rescue => ex
	p '例外'
	p ex
	result = `${BIN_DIR}/SENDMAIL.sh 9 1 #{ex}"\nhttp://www.hankyu.co.jp/railinfo/"`
else
end

def chkHankyuKyoto()
	connection = Mysql::new(DBHOST, DBUSER, DBPASS , DBSCHEMA)
	result = connection.query("SELECT DATA1 FROM nyctea_me.M_EAV WHERE CODE = 'HANKYU_KYOTO' AND CODEVALUE = 0")
	result = result.fetch_row.join

	return result.to_i
rescue => ex
	p '例外'
	p ex
else
ensure
	connection.close
end

def updHankyuKyoto(flg)
	connection = Mysql::new(DBHOST, DBUSER, DBPASS , DBSCHEMA)
	if flg == 0 then
		result = connection.query("UPDATE nyctea_me.M_EAV SET DATA1 = 0 WHERE CODE = 'HANKYU_KYOTO' AND CODEVALUE = 0")
	elsif flg == 1 then
		result = connection.query("UPDATE nyctea_me.M_EAV SET DATA1 = 1 , RCD_KSN_TIME = " + TIMESTMP + " WHERE CODE = 'HANKYU_KYOTO' AND CODEVALUE = 0")
	else
	end
	
rescue => ex
	p '例外'
	p ex
else
ensure
	connection.close
end


###############################################################################
# メイン
###############################################################################

begin
	agent = Mechanize.new
	page = agent.get('http://www.hankyu.co.jp/railinfo/')
	
	ckDelay = {
		:normal => page.search('div[@class="all_route"]/p').text,
		:kyoto => page.search('div[@class="section_inner"]/h3').text,
	}

	re = {
		:normal => /現在、20分以上の列車の遅れはございません/,
		:kyoto => /京都線/,
	}
	
	hankyu_kyoto_flg = chkHankyuKyoto()

	if ckDelay[:normal] =~ re[:normal] then
		if hankyu_kyoto_flg == 0 then
			#通常運行、なにもしない
		elsif hankyu_kyoto_flg == 1 then
			#遅延から復帰
			updHankyuKyoto(0)
			result = `${BIN_DIR}/SENDMAIL.sh 9 1 "阪急京都線 復旧\nhttp://www.hankyu.co.jp/railinfo/"`
		else
		end
	elsif ckDelay[:kyoto] =~ re[:kyoto] then
		if hankyu_kyoto_flg == 0 then
			#遅延発生
			updHankyuKyoto(1)
			getRailInfo()
			result = `${BIN_DIR}/SENDMAIL.sh 9 1 "阪急京都線 遅延発生\nhttp://www.hankyu.co.jp/railinfo/"`
		elsif hankyu_kyoto_flg == 1 then
			#遅延継続
			updHankyuKyoto(1)
			getRailInfo()
			#result = `${BIN_DIR}/SENDMAIL.sh 9 1 "阪急京都線 遅延発生\nhttp://www.hankyu.co.jp/railinfo/"`
		else
		end
	else
		if hankyu_kyoto_flg == 0 then
			#遅延発生(not京都線)
			#updHankyuKyoto(1)
			#getRailInfo()
			#result = `${BIN_DIR}/SENDMAIL.sh 9 1 "阪急 遅延発生\nhttp://www.hankyu.co.jp/railinfo/"`
		elsif hankyu_kyoto_flg == 1 then
			#遅延継続(not京都線)
			#updHankyuKyoto(1)
			#getRailInfo()
			#result = `${BIN_DIR}/SENDMAIL.sh 9 1 "阪急京都線 遅延発生\nhttp://www.hankyu.co.jp/railinfo/"`
		else
		end

	end

rescue => ex
	p '例外'
	p ex
	result = `${BIN_DIR}/SENDMAIL.sh 9 1 #{ex}"\nhttp://www.hankyu.co.jp/railinfo/"`
else
end


