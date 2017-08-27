local time = require("acid.time")

local dd = test.dd


function test.parse(t)

    for _, fmtkey, date, expected, err_code, desc in t:case_iter(4, {
        {'isobase',        '20170726T061317Z',              1501049597, nil           },
        {'iso',            '2017-07-26T06:13:17.000Z',      1501049597, nil           },
        {'utc',            'Wed, 26 Jul 2017 06:13:17 UTC', 1501049597, nil           },
        {'std',            '2017-07-26 14:13:17',           1501049597, nil           },
        {'nginxaccesslog', '26/Jul/2017:14:13:17',          1501049597, nil           },
        {'nginxerrorlog',  '2017/07/26 14:13:17',           1501049597, nil           },
        {'utc',            'Wes, 26 Jul 2017 06:13:17 UTC', nil,        'FormatError' },
        {'utc',            'wed, 26 Jul 2017 06:13:17 UTC', nil,        'FormatError' },
        {'utc',            ' 26 Jul 2017 06:13:17 UTC',     nil,        'FormatError' },
        {'utc',            'Wed, 26 Jux 2017 06:13:17 UTC', nil,        'FormatError' },
        {'utc',            'Wed, 26 2017 06:13:17 UTC',     nil,        'FormatError' },
        {'utc',            'Wed, 26 Jul 2017 06:13:17',     nil,        'FormatError' },
        {'std',            '2017-07-26 14:u:17',            nil,        'FormatError' },
        {'std',            '2017-07-26 14:13:',             nil,        'FormatError' },
        {'nginxaccesslog', '26/Jux/2017:14:13:17',          nil,        'FormatError' },
        {'nginxaccesslog', '26//2017:14:13:17',             nil,        'FormatError' },
    }) do

        local res, err, err_msg = time.parse(date, fmtkey)
        dd(date, expected)

        t:eq(expected, res, desc)
        t:eq(err_code, err, err_msg)
    end
end


function test.format(t)

    for _, fmtkey, ts, expected, err_code, desc in t:case_iter(4, {
        {'iso',            1501049597, '2017-07-26T06:13:17.000Z',      nil             },
        {'utc',            1501049597, 'Wed, 26 Jul 2017 06:13:17 UTC', nil             },
        {'std',            1501049597, '2017-07-26 14:13:17',           nil             },
        {'nginxaccesslog', 1501049597, '26/Jul/2017:14:13:17',          nil             },
        {'nginxerrorlog',  1501049597, '2017/07/26 14:13:17',           nil             },
        {'std',            nil,        nil,                             'ArgumentError' },
        {'std',            {},         nil,                             'ArgumentError' },
        {'std',            ':',        nil,                             'ArgumentError' },
        {'std',            'XxX',      nil,                             'ArgumentError' },
    }) do

        local res, err, err_msg = time.format(ts, fmtkey)
        dd(ts, expected)

        t:eq(expected, res, desc)
        t:eq(err_code, err, err_msg)
    end
end


function test.timezone(t)
    local local_time = os.time()
    local utc_time = os.time(os.date("!*t", local_time))

    local timezone = time.timezone

    t:eq(utc_time, local_time+timezone, 'timezone is wrong, timezone:' .. timezone)
end


function test.to_sec(t)

    for _, ts, expected, err_code, desc in t:case_iter(3, {
        {1503831195,              1503831195,   nil               },
        {'1503831195',            1503831195,   nil               },
        {1503831195.1,            1503831195,   nil               },
        {'1503831195.1',          1503831195,   nil               },
        {1503831195123,           1503831195,   nil               },
        {'1503831195123',         1503831195,   nil               },
        {1503831195123456,        nil,          'NumberError'     },
        {'1503831195123456',      1503831195,   nil               },
        {1503831195123456789,     nil,          'NumberError'     },
        {'1503831195123456789',   1503831195,   nil               },
        {'',                      nil,          'ArgumentError'   },
        {function() end,          nil,          'ArgumentError'   },
        {'a',                     nil,          'ArgumentError'   },
        {'abcdefghij',            nil,          'ArgumentError'   },
        {{1, 2, 3},               nil,          'ArgumentError'   },
        {true,                    nil,          'ArgumentError'   },
        {nil,                     nil,          'ArgumentError'   },
        {15038311951,             nil,          'TimeLengthError' },
        {150383119,               nil,          'TimeLengthError' },
        {-1503831195,             nil,          'NegativeError'   },
        {'1.5038311951235e+18',   nil,          'NumberError'     },
    }) do

        local res, err, err_msg = time.to_sec(ts)
        dd(ts, res)

        t:eq(expected, res, desc)
        t:eq(err_code, err, err_msg)
    end
end


function test.to_ms(t)

    for _, ts, expected, err_expected, desc in t:case_iter(3, {
        {1503831195,              1503831195000,   nil               },
        {'1503831195',            1503831195000,   nil               },
        {1503831195.1,            1503831195100,   nil               },
        {'1503831195.1',          1503831195100,   nil               },
        {1503831195.123,          1503831195123,   nil               },
        {'1503831195.123',        1503831195123,   nil               },
        {1503831195123,           1503831195123,   nil               },
        {1503831195123.0,         1503831195123,   nil               },
        {1503831195123.123,       1503831195123,   nil               },
        {1503831195123456,        nil,             'NumberError'     },
        {'1503831195123456',      1503831195123,   nil               },
        {1503831195123456789,     nil,             'NumberError'     },
        {'1503831195123456789',   1503831195123,   nil               },
        {'',                      nil,             'ArgumentError'   },
        {function() end,          nil,             'ArgumentError'   },
        {'a',                     nil,             'ArgumentError'   },
        {'abcdefghij',            nil,             'ArgumentError'   },
        {{1, 2, 3},               nil,             'ArgumentError'   },
        {true,                    nil,             'ArgumentError'   },
        {nil,                     nil,             'ArgumentError'   },
        {15038311951,             nil,             'TimeLengthError' },
        {-1503831195,             nil,             'NegativeError'   },
        {'1.5038311951235e+18',   nil,             'NumberError'     },
    }) do

        local rst, err, errmsg = time.to_ms(ts)
        dd(ts, rst)

        t:eq(expected, rst, desc)
        t:eq(err_expected, err, errmsg)
    end
end


function test.to_str_ns(t)

    for _, ts, expected, err_expected, desc in t:case_iter(3, {
        {1503831195,                '1503831195000000000',   nil               },
        {'1503831195',              '1503831195000000000',   nil               },
        {1503831195.123456,         '1503831195123500000',   nil               },
        {'1503831195.123456',       '1503831195123456000',   nil               },
        {1503831195123,             '1503831195123000000',   nil               },
        {1503831195123.123,         '1503831195123100000',   nil               },
        {'1503831195123.123',       '1503831195123123000',   nil               },
        {1503831195123456,          nil,                     'NumberError'     },
        {'1503831195123456',        '1503831195123456000',   nil               },
        {1503831195123456.123,      nil,                     'NumberError'     },
        {'1503831195123456.123',    '1503831195123456123',   nil               },
        {1503831195123456789,       nil,                     'NumberError'     },
        {'1503831195123456789',     '1503831195123456789',   nil               },
        {'',                        nil,                     'ArgumentError'   },
        {function() end,            nil,                     'ArgumentError'   },
        {'a',                       nil,                     'ArgumentError'   },
        {'abcdefghij',              nil,                     'ArgumentError'   },
        {{1, 2, 3},                 nil,                     'ArgumentError'   },
        {true,                      nil,                     'ArgumentError'   },
        {nil,                       nil,                     'ArgumentError'   },
        {15038311951,               nil,                     'TimeLengthError' },
        {-1503831195,               nil,                     'NegativeError'   },
        {'1.5038311951235e+18',     nil,                     'NumberError'     },
    }) do

        local rst, err, errmsg = time.to_str_ns(ts)
        dd(ts, rst)

        t:eq(expected, rst, desc)
        t:eq(err_expected, err, errmsg)
    end
end


function test.to_str_us(t)

    for _, ts, expected, err_expected, desc in t:case_iter(3, {
        {1503831195,                '1503831195000000',    nil               },
        {'1503831195',              '1503831195000000',    nil               },
        {1503831195.123,            '1503831195123000',    nil               },
        {'1503831195.123',          '1503831195123000',    nil               },
        {1503831195.123456,         '1503831195123500',    nil               },
        {'1503831195.123456',       '1503831195123456',    nil               },
        {1503831195123,             '1503831195123000',    nil               },
        {'1503831195123',           '1503831195123000',    nil               },
        {1503831195123.123,         '1503831195123100',    nil               },
        {'1503831195123.123',       '1503831195123123',    nil               },
        {1503831195123456,          nil,                   'NumberError'     },
        {'1503831195123456',        '1503831195123456',    nil               },
        {1503831195123456789,       nil,                   'NumberError'     },
        {'1503831195123456789',     '1503831195123456',    nil               },
        {'',                        nil,                   'ArgumentError'   },
        {function() end,            nil,                   'ArgumentError'   },
        {'a',                       nil,                   'ArgumentError'   },
        {'abcdefghij',              nil,                   'ArgumentError'   },
        {{1, 2, 3},                 nil,                   'ArgumentError'   },
        {true,                      nil,                   'ArgumentError'   },
        {nil,                       nil,                   'ArgumentError'   },
        {15038311951,               nil,                   'TimeLengthError' },
        {-1503831195,               nil,                   'NegativeError'   },
        {'1.5038311951235e+18',     nil,                   'NumberError'     },
    }) do

        local rst, err, errmsg = time.to_str_us(ts)
        dd(ts, rst)

        t:eq(expected, rst, desc)
        t:eq(err_expected, err, errmsg)
    end
end
