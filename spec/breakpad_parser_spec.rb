require 'spec_helper'

describe SentryBreakpad::BreakpadParser do
  
  describe '.raven_event_hash' do
    let(:breakpad_report_content) { read_fixture('breakpad_report') }

    let(:expected_hash) do
      {
        "culprit"    => "ETClient.exe!QString::~QString()",
        "extra"      => {"crash_address"=>"0xfffffffffee1dead", "crashed_thread_id"=>0},
        "interfaces" => {"stacktrace"=>{"frames"=>[{"filename"=>"unknown", "function"=>"ETClient.exe!WinMain"}, {"filename"=>"unknown", "function"=>"ETClient.exe!QApplication::notify(QObject *,QEvent *)"}, {"filename"=>"unknown", "function"=>"ETClient.exe!QApplicationPrivate::notify_helper(QObject *,QEvent *)"}, {"filename"=>"unknown", "function"=>"ETClient.exe!QLabel::event(QEvent *)"}, {"filename"=>"unknown", "function"=>"ETClient.exe!QFrame::event(QEvent *)"}, {"filename"=>"unknown", "function"=>"ETClient.exe!QWidget::event(QEvent *)"}, {"filename"=>"togglebuttonwid.cpp", "function"=>"ETClient.exe!ToggleButtonWid::mousePressEvent(QMouseEvent *)", "lineno"=>122}, {"filename"=>"moc_togglebuttonwid.cpp", "function"=>"ETClient.exe!ToggleButtonWid::sig_buttonClicked()", "lineno"=>123}, {"filename"=>"unknown", "function"=>"ETClient.exe!QMetaObject::activate(QObject *,QMetaObject const *,int,void * *)"}, {"filename"=>"unknown", "function"=>"ETClient.exe!QMetaObject::activate(QObject *,int,int,void * *)"}, {"filename"=>"moc_machinelistitem.cpp", "function"=>"ETClient.exe!MachineListItem::qt_static_metacall(QObject *,QMetaObject::Call,int,void * *)", "lineno"=>115}, {"filename"=>"machinelistitem.cpp", "function"=>"ETClient.exe!MachineListItem::on_EditButtonClicked()", "lineno"=>197}, {"filename"=>"machinelistitem.cpp", "function"=>"ETClient.exe!buggyFunc()", "lineno"=>181}, {"filename"=>"unknown", "function"=>"ETClient.exe!QString::`scalar deleting destructor'(unsigned int)"}, {"filename"=>"qstring.h", "function"=>"ETClient.exe!QString::~QString()", "lineno"=>992}]}},
        "message"    => "EXCEPTION_ACCESS_VIOLATION_READ at ETClient.exe!QString::~QString() (qstring.h : 992)",
        "modules"    => {"ETClient.exe"=>"???", "libeay32.dll"=>"1.0.2.4", "msvcp120.dll"=>"12.0.21005.1", "ssleay32.dll"=>"1.0.2.4", "uxtheme.dll"=>"6.1.7600.16385", "dwmapi.dll"=>"6.1.7601.18917", "RpcRtRemote.dll"=>"6.1.7601.17514", "rsaenh.dll"=>"6.1.7600.16385", "webio.dll"=>"6.1.7601.17725", "winhttp.dll"=>"6.1.7601.17514", "cryptsp.dll"=>"6.1.7601.18741", "dbghelp.dll"=>"6.1.7601.17514", "dhcpcsvc6.DLL"=>"6.1.7601.17970", "dhcpcsvc.dll"=>"6.1.7600.16385", "winnsi.dll"=>"6.1.7600.16385", "IPHLPAPI.DLL"=>"6.1.7601.17514", "WSHTCPIP.DLL"=>"6.1.7600.16385", "mswsock.dll"=>"6.1.7601.18254", "winmm.dll"=>"6.1.7601.17514", "powrprof.dll"=>"6.1.7600.16385", "wlanutil.dll"=>"6.1.7600.16385", "d3d9.dll"=>"4.3.22.0", "msvcr120.dll"=>"12.0.21005.1", "wlanapi.dll"=>"6.1.7600.16385", "credssp.dll"=>"6.1.7601.19110", "CRYPTBASE.dll"=>"6.1.7601.19110", "sspicli.dll"=>"6.1.7601.19110", "shell32.dll"=>"6.1.7601.18952", "lpk.dll"=>"6.1.7601.18985", "msvcrt.dll"=>"7.0.7601.17744", "devobj.dll"=>"6.1.7601.17621", "msasn1.dll"=>"6.1.7601.17514", "shlwapi.dll"=>"6.1.7601.17514", "kernel32.dll"=>"6.1.7601.19110", "advapi32.dll"=>"6.1.7601.19091", "oleaut32.dll"=>"6.1.7601.18679", "rpcrt4.dll"=>"6.1.7601.19110", "crypt32.dll"=>"6.1.7601.18839", "usp10.dll"=>"1.626.7601.19054", "gdi32.dll"=>"6.1.7601.19091", "msctf.dll"=>"6.1.7601.18731", "nsi.dll"=>"6.1.7600.16385", "ole32.dll"=>"6.1.7601.18915", "setupapi.dll"=>"6.1.7601.17514", "ws2_32.dll"=>"6.1.7601.17514", "profapi.dll"=>"6.1.7600.16385", "sechost.dll"=>"6.1.7601.18869", "user32.dll"=>"6.1.7601.19061", "KERNELBASE.dll"=>"6.1.7601.19110", "imm32.dll"=>"6.1.7601.17514", "cfgmgr32.dll"=>"6.1.7601.17621", "ntdll.dll"=>"6.1.7601.19110"},
        "tags"       => {"os"=>"Windows NT", "os_full"=>"Windows NT - 6.1.7601 Service Pack 1", "cpu"=>"x86", "cpu_full"=>"x86 - GenuineIntel family 6 model 70 stepping 1 - 4 CPUs"},
        "level"      => "fatal",
        "logger"     => "breakpad"
      }
    end

    let(:parser) { described_class.new(breakpad_report_content) }

    it 'returns the expected result' do
      expect(parser.raven_event_hash(false)).to eq(expected_hash)
    end

    it 'includes the raw report in extra by default' do
      hash = parser.raven_event_hash
      base_extra = expected_hash['extra']

      expect(hash['extra']).to eq(base_extra.merge({'raw_breakpad_report' => breakpad_report_content}))
    end
  end
end
