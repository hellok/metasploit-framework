##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'
require 'msf/core/post/common'
require 'msf/core/post/file'
require 'msf/core/post/linux/system'

class Metasploit3 < Msf::Post

	include Msf::Post::Common
	include Msf::Post::File
	include Msf::Post::Linux::System

	def initialize(info={})
		super( update_info( info,
			'Name'          => 'Linux Gather Protection Enumeration',
			'Description'   => %q{
				This module tries to find certain installed applications that can be used
				to prevent, or detect our attacks, which is done by locating certain
				binary locations, and see if they are indeed executables.  For example,
				if we are able to run 'snort' as a command, we assume it's one of the files
				we are looking for.

				This module is meant to cover various antivirus, rootkits, IDS/IPS,
				firewalls, and other software.
			},
			'License'       => MSF_LICENSE,
			'Author'        =>
				[
					'ohdae <bindshell[at]live.com>',
				],
			'Version'       => '$Revision$',
			'Platform'      => [ 'linux' ],
			'SessionTypes'  => [ 'shell' ]
		))
	end

	def run
		distro = get_sysinfo
		h = get_host
		print_status("Running module against #{h}")
		print_status("Info:")
		print_status("\t#{distro[:version]}")
		print_status("\t#{distro[:kernel]}")
		
		vprint_status("Finding installed applications...")
		find_apps
	end

	def get_host
		case session.type
		when /meterpreter/
			host = sysinfo["Computer"]
		when /shell/
			host = session.shell_command_token("hostname").chomp
		end

		return host
	end

	def which(cmd)
		exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
		ENV['PATH'].split(::File::PATH_SEPARATOR).each do |path|
			exts.each { |ext|
				exe = "#{path}/#{cmd}#{ext}"
				return exe if ::File.executable? exe
			}
		end
		return nil
	end

	def find_apps
		apps = [
			"truecrypt", "bulldog", "ufw", "iptables", "logrotate", "logwatch",
			"chkrootkit", "clamav", "snort", "tiger", "firestarter", "avast", "lynis",
			"rkhunter", "tcpdump", "webmin", "jailkit", "pwgen", "proxychains", "bastille",
			"psad", "wireshark", "nagios", "nagios", "apparmor"
		]

		apps.each do |a|
			output = which("#{a}")
 			if output
				print_good("#{a} found: #{output}")

				report_note(
					:host_name => get_host,
					:type      => "protection",
					:data      => output,
					:update    => :unique_data
				)
			end
		end

		print_status("Installed applications saved to notes.")
	end
end
