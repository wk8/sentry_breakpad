# SentryBreakpad

So you've integrated [Google
Breakpad](https://chromium.googlesource.com/breakpad/breakpad/) into your C/C++
application, and that gives you nicely formatted reports, such as

```
Operating system: Windows NT
                  6.1.7601 Service Pack 1
CPU: x86
     GenuineIntel family 6 model 70 stepping 1
     4 CPUs

Crash reason:  EXCEPTION_ACCESS_VIOLATION_READ
Crash address: 0xfffffffffee1dead

Thread 0 (crashed)
 0  ETClient.exe!QString::~QString() [qstring.h : 992 + 0xa]
    eip = 0x00d74e3a   esp = 0x0018d1b4   ebp = 0x0018d1b8   ebx = 0x01ad947c
    esi = 0x05850000   edi = 0x058277f8   eax = 0xfee1dead   ecx = 0xfee1dead
    edx = 0x00000004   efl = 0x00210282
    Found by: given as instruction pointer in context
 1  ETClient.exe!QString::`scalar deleting destructor'(unsigned int) + 0xf
    eip = 0x00d9161f   esp = 0x0018d1c0   ebp = 0x0018d1c4
    Found by: call frame info
 2  ETClient.exe!buggyFunc() [machinelistitem.cpp : 181 + 0x1d]
    eip = 0x00daaea3   esp = 0x0018d1cc   ebp = 0x0018d1dc
    Found by: call frame info
 3  ETClient.exe!MachineListItem::on_EditButtonClicked() [machinelistitem.cpp : 197 + 0x5]
    eip = 0x00da5dd4   esp = 0x0018d1e4   ebp = 0x0018d250
    Found by: call frame info
 4  ETClient.exe!MachineListItem::qt_static_metacall(QObject *,QMetaObject::Call,int,void * *) [moc_machinelistitem.cpp : 115 + 0x8]
    eip = 0x00de14a1   esp = 0x0018d258   ebp = 0x0018d27c
    Found by: call frame info
 5  ETClient.exe!QMetaObject::activate(QObject *,int,int,void * *) + 0x4cf
    eip = 0x0135329f   esp = 0x0018d284   ebp = 0x00000000
    Found by: call frame info

Thread 1
 0  ntdll.dll + 0x2019d
    eip = 0x7744019d   esp = 0x03bffb64   ebp = 0x03bffcf8   ebx = 0x7745c4f8
    esi = 0x003d9148   edi = 0x00000000   eax = 0x00000000   ecx = 0x00000000
    edx = 0x00000000   efl = 0x00000246
    Found by: given as instruction pointer in context
 1  kernel32.dll + 0x1338a
    eip = 0x75d3338a   esp = 0x03bffd00   ebp = 0x03bffd04
    Found by: previous frame's frame pointer
 2  ntdll.dll + 0x39882
    eip = 0x77459882   esp = 0x03bffd0c   ebp = 0x03bffd44
    Found by: previous frame's frame pointer
 3  ntdll.dll + 0x39855
    eip = 0x77459855   esp = 0x03bffd4c   ebp = 0x03bffd5c
    Found by: previous frame's frame pointer

Thread 2
 0  ntdll.dll + 0x21f86
    eip = 0x77441f86   esp = 0x00d4f770   ebp = 0x00d4f8d0   ebx = 0x00010003
    esi = 0x00000002   edi = 0x003dc490   eax = 0x00000001   ecx = 0x00000000
    edx = 0x00000000   efl = 0x00000246
    Found by: given as instruction pointer in context
 1  kernel32.dll + 0x1338a
    eip = 0x75d3338a   esp = 0x00d4f8d8   ebp = 0x00d4f8dc
    Found by: previous frame's frame pointer
 2  ntdll.dll + 0x39882
    eip = 0x77459882   esp = 0x00d4f8e4   ebp = 0x00d4f91c
    Found by: previous frame's frame pointer
 3  ntdll.dll + 0x39855
    eip = 0x77459855   esp = 0x00d4f924   ebp = 0x00d4f934
    Found by: previous frame's frame pointer

Loaded modules:
0x00d70000 - 0x01b39fff  ETClient.exe  ???  (main)
0x67070000 - 0x671a8fff  libeay32.dll  1.0.2.4
0x71020000 - 0x71090fff  msvcp120.dll  12.0.21005.1
0x71370000 - 0x713bbfff  ssleay32.dll  1.0.2.4
0x72470000 - 0x724effff  uxtheme.dll  6.1.7600.16385
0x726e0000 - 0x726f2fff  dwmapi.dll  6.1.7601.18917
0x73160000 - 0x7316dfff  RpcRtRemote.dll  6.1.7601.17514
0x731e0000 - 0x7321afff  rsaenh.dll  6.1.7600.16385
0x73250000 - 0x7329efff  webio.dll  6.1.7601.17725
0x732a0000 - 0x732f7fff  winhttp.dll  6.1.7601.17514
0x73380000 - 0x73396fff  cryptsp.dll  6.1.7601.18741
```

All well and good, but it's hard to reliably keep track of these reports... what bugs
are new, which should be resolved, which are happening the most...?

Then you think you could use [Sentry](https://getsentry.com) to help you track your
Breakpad reports.

This gem makes it easy to parse Breakpad reports like the above and format them into
Sentry events.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sentry_breakpad'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sentry_breakpad

## Usage

Simply feed the content of a breakpad report to `SentryBreakpad.send_from_string`

```ruby
my_breakpad_report = "Operating system: Windows NT\n                  6.1.7601 Service Pack 1..."
SentryBreakpad.send_from_string(my_breakpad_report)
```

If you want, you can also use `SentryBreakpad.send_from_file` instead, to read a
breakpad report from the disk, and send it to Sentry:

```ruby
SentryBreakpad.send_from_file('/path/to/report')
```

Both functions take an extra argument to allow you to add extra information to the
generated Sentry event, e.g.:

```ruby
SentryBreakpad.send_from_file('/path/to/report', {
  'release' => '12.4',
  'extra' => {
    'time_running' => 25632
  },
  'tags' => {
    'build_type' => 'release'
  }
})
```

The exhaustive list of all the extra information that can be passed can be found
at https://github.com/getsentry/raven-ruby/blob/0.15.3/lib/raven/event.rb#L31-L49.

Please note that all of the above assumes that `Raven` has been properly configured
(we use `Raven.client` to send the generated events)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wk8/sentry_breakpad.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
