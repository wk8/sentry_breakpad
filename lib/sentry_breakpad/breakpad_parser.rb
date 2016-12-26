require 'raven'

module SentryBreakpad
  # parses a breakpad report and turns it into a Raven event
  class BreakpadParser # rubocop:disable Metrics/ClassLength # TODO wkpo needed?
    def self.from_file(file_path)
      new(File.open(file_path).read)
    end

    def initialize(breakpad_report_content)
      @breakpad_report_content = breakpad_report_content

      @message = nil
      @tags = {}
      @crashed_thread_stacktrace = []
      @culprit = nil
      @modules = {}
      @extra = {}

      parse!
    end

    # TODO wkpo unit test on the extra_info thing
    def raven_event(extra_info = {})
      hash = deep_merge(raven_event_hash, extra_info)
      Raven::Event.new(hash).tap do |event|
        event[:stacktrace] = { frames: @crashed_thread_stacktrace }
      end
    end

    # TODO wkpo private
    def raven_event_hash
      {
        'message'    => @message,
        'tags'       => @tags,
        'culprit'    => @culprit,
        'modules'    => @modules,
        'extra'      => @extra,
        'level'      => 'fatal',
        'logger'     => 'breakpad'
      }
    end

  private

    def parse!
      parse_lines(@breakpad_report_content.split("\n").reverse!)
    end

    def parse_lines(lines) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/LineLength
      until lines.empty?
        case lines.last
        when /^Operating system:/
          parse_operating_system(lines)
        when /^CPU: /
          parse_cpu(lines)
        when /^Crash reason:/
          parse_crash_reason(lines.pop)
        when /^Crash address:/
          parse_crash_address(lines.pop)
        when /^Thread ([0-9]+) \(crashed\)/
          parse_crashed_thread_stacktrace(lines, Regexp.last_match[1].to_i)
        when /^Loaded modules:/
          parse_loaded_modules(lines)
        else
          lines.pop
        end
      end
    end

    # Parses something of the form
    # Operating system: Windows NT
    #                   6.1.7601 Service Pack 1
    def parse_operating_system(lines)
      parse_indented_section(lines, 'Operating system:', 'os')

      if @tags['os']
        @extra[:server] ||= {}
        @extra[:server][:os] = {
          name: @tags['os'],
          version: @tags['os_full']
        }
      end
    end

    # Parses something of the form
    # CPU: x86
    #      GenuineIntel family 6 model 70 stepping 1
    #      4 CPUs
    def parse_cpu(lines)
      parse_indented_section(lines, 'CPU:', 'cpu')
    end

    def parse_indented_section(lines, prefix, tag_name)
      short = remove_prefix(lines.pop, prefix)
      long = short

      while lines.last && lines.last.start_with?(' ')
        long += ' - ' + lines.pop.strip
      end

      @tags[tag_name] = short
      @tags["#{tag_name}_full"] = long
    end

    # Parses a single line like
    # Crash reason: EXCEPTION_ACCESS_VIOLATION_READ
    def parse_crash_reason(line)
      reason = remove_prefix(line, 'Crash reason:')

      @message = if @message.nil?
                   reason
                 else
                   # we parse the crashed thread first
                   "#{reason} at #{@message}"
                 end
    end

    # Parses a single line like
    # Crash address: 0xfffffffffee1dead
    def parse_crash_address(line)
      address = remove_prefix(line, 'Crash address:')

      @extra[:crash_address] = address
    end

    def remove_prefix(line, prefix)
      line.slice!(prefix)
      line.strip
    end

    BACKTRACE_LINE_REGEX = /^\s*([0-9]+)\s+(.*)\s+(?:\[(([^ ]+)\s+:\s+([0-9]+))\s+\+\s+0x[0-9a-f]+\]|\+\s+0x[0-9a-f]+)\s*$/ # rubocop:disable Metrics/LineLength

    # rubocop:disable Metrics/LineLength
    # Parses something of the form
    # Thread 0 (crashed)
    #  0  ETClient.exe!QString::~QString() [qstring.h : 992 + 0xa]
    #     eip = 0x00d74e3a   esp = 0x0018d1b4   ebp = 0x0018d1b8   ebx = 0x01ad947c
    #     esi = 0x05850000   edi = 0x058277f8   eax = 0xfee1dead   ecx = 0xfee1dead
    #     edx = 0x00000004   efl = 0x00210282
    #     Found by: given as instruction pointer in context
    #  1  ETClient.exe!QString::`scalar deleting destructor'(unsigned int) + 0xf
    #     eip = 0x00d9161f   esp = 0x0018d1c0   ebp = 0x0018d1c4
    #     Found by: call frame info
    #  2  ETClient.exe!buggyFunc() [machinelistitem.cpp : 181 + 0x1d]
    #     eip = 0x00daaea3   esp = 0x0018d1cc   ebp = 0x0018d1dc
    #     Found by: call frame info
    #  3  ETClient.exe!MachineListItem::on_EditButtonClicked() [machinelistitem.cpp : 197 + 0x5]
    #     eip = 0x00da5dd4   esp = 0x0018d1e4   ebp = 0x0018d250
    #     Found by: call frame info
    #  4  ETClient.exe!MachineListItem::qt_static_metacall(QObject *,QMetaObject::Call,int,void * *) [moc_machinelistitem.cpp : 115 + 0x8]
    #     eip = 0x00de14a1   esp = 0x0018d258   ebp = 0x0018d27c
    #     Found by: call frame info
    #  5  ETClient.exe!QMetaObject::activate(QObject *,int,int,void * *) + 0x4cf
    #     eip = 0x0135329f   esp = 0x0018d284   ebp = 0x00000000
    #     Found by: call frame info
    #  6  ETClient.exe!QMetaObject::activate(QObject *,QMetaObject const *,int,void * *) + 0x1e
    #     eip = 0x0135345e   esp = 0x0018d304   ebp = 0x0018d32c
    #     Found by: call frame info
    #  7  ETClient.exe!ToggleButtonWid::sig_buttonClicked() [moc_togglebuttonwid.cpp : 123 + 0x12]
    #     eip = 0x00de2759   esp = 0x0018d318   ebp = 0x0018d32c
    #     Found by: call frame info
    #  8  ETClient.exe!ToggleButtonWid::mousePressEvent(QMouseEvent *) [togglebuttonwid.cpp : 122 + 0x8]
    #     eip = 0x00dcac14   esp = 0x0018d334   ebp = 0x0018d338
    #     Found by: call frame info
    #  9  ETClient.exe!QWidget::event(QEvent *) + 0x89
    #     eip = 0x00df4fa9   esp = 0x0018d340   ebp = 0x05821ae0
    #     Found by: call frame info
    # 10  ETClient.exe!QFrame::event(QEvent *) + 0x20
    #     eip = 0x00e17280   esp = 0x0018d40c   ebp = 0x0018d7f8
    #     Found by: call frame info
    # 11  ETClient.exe!QLabel::event(QEvent *) + 0xdf
    #     eip = 0x00e0714f   esp = 0x0018d420   ebp = 0x0018d7f8
    #     Found by: call frame info
    # 12  ETClient.exe!QApplicationPrivate::notify_helper(QObject *,QEvent *) + 0x98
    #     eip = 0x00e1de08   esp = 0x0018d434   ebp = 0x0033c6f8
    #     Found by: call frame info
    # 13  ETClient.exe!QApplication::notify(QObject *,QEvent *) + 0x659
    #     eip = 0x00e1c5e9   esp = 0x0018d448   ebp = 0x0018d7f8
    #     Found by: call frame info
    # 14  ETClient.exe!WinMain + 0x21358
    #     eip = 0x015bb068   esp = 0x0018d690   ebp = 0x0018d7f8
    #     Found by: call frame info
    # rubocop:enable Metrics/LineLength
    def parse_crashed_thread_stacktrace(lines, thread_id)
      # remove the 1st line
      lines.pop

      stacktrace = []
      process_matching_lines(lines, BACKTRACE_LINE_REGEX) do |match|
        stacktrace << parse_crashed_thread_stacktrace_line(match)
      end

      # sentry wants their stacktrace with the oldest frame first
      @crashed_thread_stacktrace = stacktrace.reverse

      @extra[:crashed_thread_id] = thread_id
    end

    def parse_crashed_thread_stacktrace_line(match)
      frame_nb, function, filename, lineno = match[1], match[2], match[4] || 'unknown', match[5]

      parse_culprit_and_message(function, match[3]) if frame_nb.to_i == 0

      {
        'filename' => filename,
        'function' => function
      }.tap { |frame| frame['lineno'] = lineno.to_i if lineno }
    end

    def parse_culprit_and_message(function, file_name_and_lineno)
      @culprit = function

      message_tail = function
      message_tail += " (#{file_name_and_lineno})" if file_name_and_lineno

      if @message.nil?
        @message = message_tail
      else
        # already parsed the crash reason
        @message += " at #{message_tail}"
      end
    end

    MODULE_LINE_REGEX = /0x[0-9a-f]+\s+-\s+0x[0-9a-f]+\s+([^ ]+)\s+([^ ]+)/

    # rubocop:disable Metrics/LineLength
    # Parses something of the form
    # Loaded modules:
    # 0x00d70000 - 0x01b39fff  ETClient.exe  ???  (main)
    # 0x67070000 - 0x671a8fff  libeay32.dll  1.0.2.4
    # 0x71020000 - 0x71090fff  msvcp120.dll  12.0.21005.1
    # 0x71370000 - 0x713bbfff  ssleay32.dll  1.0.2.4
    # 0x72470000 - 0x724effff  uxtheme.dll  6.1.7600.16385
    # 0x726e0000 - 0x726f2fff  dwmapi.dll  6.1.7601.18917
    # 0x73160000 - 0x7316dfff  RpcRtRemote.dll  6.1.7601.17514
    # 0x731e0000 - 0x7321afff  rsaenh.dll  6.1.7600.16385
    # 0x73250000 - 0x7329efff  webio.dll  6.1.7601.17725
    # 0x732a0000 - 0x732f7fff  winhttp.dll  6.1.7601.17514
    # 0x73380000 - 0x73396fff  cryptsp.dll  6.1.7601.18741
    # 0x733b0000 - 0x7349afff  dbghelp.dll  6.1.7601.17514
    # 0x736e0000 - 0x736ecfff  dhcpcsvc6.DLL  6.1.7601.17970
    # 0x736f0000 - 0x73701fff  dhcpcsvc.dll  6.1.7600.16385
    # 0x73710000 - 0x73716fff  winnsi.dll  6.1.7600.16385
    # 0x73720000 - 0x7373bfff  IPHLPAPI.DLL  6.1.7601.17514
    # 0x73740000 - 0x73744fff  WSHTCPIP.DLL  6.1.7600.16385
    # 0x73750000 - 0x7378bfff  mswsock.dll  6.1.7601.18254
    # 0x73790000 - 0x737c1fff  winmm.dll  6.1.7601.17514
    # 0x737d0000 - 0x737f4fff  powrprof.dll  6.1.7600.16385
    # 0x73800000 - 0x73805fff  wlanutil.dll  6.1.7600.16385
    # 0x73810000 - 0x73824fff  d3d9.dll  4.3.22.0
    # 0x73850000 - 0x7393dfff  msvcr120.dll  12.0.21005.1
    # 0x73cc0000 - 0x73cd5fff  wlanapi.dll  6.1.7600.16385
    # 0x74d40000 - 0x74d47fff  credssp.dll  6.1.7601.19110
    # 0x74d70000 - 0x74d7bfff  CRYPTBASE.dll  6.1.7601.19110
    # 0x74d80000 - 0x74ddffff  sspicli.dll  6.1.7601.19110
    # 0x74e80000 - 0x75acafff  shell32.dll  6.1.7601.18952
    # 0x75b30000 - 0x75b39fff  lpk.dll  6.1.7601.18985
    # 0x75b40000 - 0x75bebfff  msvcrt.dll  7.0.7601.17744
    # 0x75bf0000 - 0x75c01fff  devobj.dll  6.1.7601.17621
    # 0x75c10000 - 0x75c1bfff  msasn1.dll  6.1.7601.17514
    # 0x75c80000 - 0x75cd6fff  shlwapi.dll  6.1.7601.17514
    # 0x75d20000 - 0x75e2ffff  kernel32.dll  6.1.7601.19110  (WARNING: No symbols, wkernel32.pdb, 5B44EEB548A94000AB2677B80472D6442)
    # 0x75e30000 - 0x75ed0fff  advapi32.dll  6.1.7601.19091
    # 0x75ee0000 - 0x75f6efff  oleaut32.dll  6.1.7601.18679
    # 0x75f70000 - 0x7605ffff  rpcrt4.dll  6.1.7601.19110
    # 0x76090000 - 0x761b0fff  crypt32.dll  6.1.7601.18839
    # 0x761e0000 - 0x7627cfff  usp10.dll  1.626.7601.19054
    # 0x76280000 - 0x7630ffff  gdi32.dll  6.1.7601.19091
    # 0x76310000 - 0x763dbfff  msctf.dll  6.1.7601.18731
    # 0x763e0000 - 0x763e5fff  nsi.dll  6.1.7600.16385
    # 0x76420000 - 0x7657bfff  ole32.dll  6.1.7601.18915  (WARNING: No symbols, ole32.pdb, DE14A7E1B047414B826E606585170A892)
    # 0x76580000 - 0x7671cfff  setupapi.dll  6.1.7601.17514
    # 0x76a80000 - 0x76ab4fff  ws2_32.dll  6.1.7601.17514
    # 0x76ac0000 - 0x76acafff  profapi.dll  6.1.7600.16385
    # 0x76ad0000 - 0x76ae8fff  sechost.dll  6.1.7601.18869
    # 0x76af0000 - 0x76beffff  user32.dll  6.1.7601.19061  (WARNING: No symbols, wuser32.pdb, 9B8CF996B7584AC1ADA9DB5CADE512922)
    # 0x76c80000 - 0x76cc6fff  KERNELBASE.dll  6.1.7601.19110  (WARNING: No symbols, wkernelbase.pdb, A0567C574144432389F2D6539B69AA161)
    # 0x76f90000 - 0x76feffff  imm32.dll  6.1.7601.17514
    # 0x76ff0000 - 0x77016fff  cfgmgr32.dll  6.1.7601.17621
    # 0x77420000 - 0x7759ffff  ntdll.dll  6.1.7601.19110  (WARNING: No symbols, wntdll.pdb, 992AA396746C4D548F7F497DD63B4EEC2)
    # rubocop:enable Metrics/LineLength
    def parse_loaded_modules(lines)
      # remove the 1st line
      lines.pop

      process_matching_lines(lines, MODULE_LINE_REGEX) do |match|
        name    = match[1]
        version = match[2]

        @modules[name] = version
      end
    end

    def process_matching_lines(lines, regex, &_blk)
      loop do
        line = lines.pop
        line.strip! if line

        break if !line || line.empty?

        match = regex.match(line)
        yield(match) if match
      end
    end

    # merges hash2 into hash1, recursively
    # wish ActiveSupport was around...
    def deep_merge(hash1, hash2)
      hash2.each do |key, value|
        hash1[key] = if hash1.key?(value) && hash1[key].is_a?(Hash) && value.is_a?(Hash)
                       deep_merge(hash1[key], value)
                     else
                       value
                     end
      end

      hash1
    end
  end
end
