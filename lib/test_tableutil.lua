local tableutil = require("acid.tableutil")

local dd = test.dd


function test.nkeys(t)
    local cases = {
        {0, {              }, 'nkeys of empty'},
        {1, {0             }, 'nkeys of 1'},
        {2, {0, nil, 1     }, 'nkeys of 0, nil and 1'},
        {2, {0, 1          }, 'nkeys of 2'},
        {2, {0, 1, nil     }, 'nkeys of 0, 1 and nil'},
        {1, {a=0, nil      }, 'nkeys of a=1'},
        {2, {a=0, b=2, nil }, 'nkeys of a=1'},
    }

    for ii, c in ipairs(cases) do
        local n, tbl = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = tableutil.nkeys(tbl)
        t:eq(n, rst, msg)

        rst = tableutil.get_len(tbl)
        t:eq(n, rst, msg)
    end
end

function test.keys(t)
    t:eqdict( {}, tableutil.keys({}) )
    t:eqdict( {1}, tableutil.keys({1}) )
    t:eqdict( {1, 'a'}, tableutil.keys({1, a=1}) )
    t:eqdict( {1, 2, 'a'}, tableutil.keys({1, 3, a=1}) )
end

function test.duplist(t)
    local du = tableutil.duplist

    local a = { 1 }
    local b = tableutil.duplist( a )
    a[ 2 ] = 2
    t:eq( nil, b[ 2 ], "dup not affected" )

    t:eqdict( {1}, du( { 1, nil, 2 } ) )
    t:eqdict( {1}, du( { 1, a=3 } ) )
    t:eqdict( {1}, du( { 1, [3]=3 } ) )
    t:eqdict( {}, du( { a=1, [3]=3 } ) )

    a = { { 1, 2, 3, a=4 } }
    a[2] = a[1]
    b = du(a)
    t:eqdict({ { 1, 2, 3, a=4 }, { 1, 2, 3, a=4 } }, b)
    t:eq( b[1], b[2] )
end

function test.sub(t)
    local a = { a=1, b=2, c={} }
    t:eqdict( {}, tableutil.sub( a, nil ) )
    t:eqdict( {}, tableutil.sub( a, {} ) )
    t:eqdict( {b=2}, tableutil.sub( a, {"b"} ) )
    t:eqdict( {a=1, b=2}, tableutil.sub( a, {"a", "b"} ) )

    local b = tableutil.sub( a, {"a", "b", "c"} )
    t:neq( b, a )
    t:eq( b.c, a.c, "reference" )

    -- explicitly specify to sub() as a table
    b = tableutil.sub( a, {"a", "b", "c"}, 'table' )
    t:neq( b, a )
    t:eq( b.c, a.c, "reference" )

    -- sub list

    local cases = {
        {{1, 2, 3}, {}, {}},
        {{1, 2, 3}, {2, 3}, {2, 3}},
        {{1, 2, 3}, {2, 3, 4}, {2, 3}},
        {{1, 2, 3}, {3, 4, 2}, {3, 2}},
    }

    for ii, c in ipairs(cases) do
        local tbl, ks, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = tableutil.sub(tbl, ks, 'list')
        t:eqdict(expected, rst)
    end
end

function test.dup(t)
    local a = { a=1, 10, x={ y={z=3} } }
    a.self = a
    a.selfref = a
    a.x2 = a.x

    local b = tableutil.dup( a )
    b.a = 'b'
    t:eq( 1, a.a, 'dup not affected' )
    t:eq( 10, a[ 1 ], 'a has 10' )
    t:eq( 10, b[ 1 ], 'b inherit 10' )
    b[ 1 ] = 11
    t:eq( 10, a[ 1 ], 'a has still 10' )

    a.x.y.z = 4
    t:eq( 4, b.x.y.z, 'no deep' )

    local deep = tableutil.dup( a, true )
    a.x.y.z = 5
    t:eq( 4, deep.x.y.z, 'deep dup' )
    t:eq( deep, deep.self, 'loop reference' )
    t:eq( deep, deep.selfref, 'loop reference should be dup only once' )
    t:eq( deep.x, deep.x2, 'dup only once' )
    t:neq( a.x, deep.x, 'dup-ed x' )
    t:eq( deep.x.y, deep.x2.y )

end

function test.contains(t)
    local c = tableutil.contains
    t:eq( true, c( nil, nil ) )
    t:eq( true, c( 1, 1 ) )
    t:eq( true, c( "", "" ) )
    t:eq( true, c( "a", "a" ) )

    t:eq( false, c( 1, 2 ) )
    t:eq( false, c( 1, nil ) )
    t:eq( false, c( nil, 1 ) )
    t:eq( false, c( {}, 1 ) )
    t:eq( false, c( {}, "" ) )
    t:eq( false, c( "", {} ) )
    t:eq( false, c( 1, {} ) )

    t:eq( true, c( {}, {} ) )
    t:eq( true, c( {1}, {} ) )
    t:eq( true, c( {1}, {1} ) )
    t:eq( true, c( {1, 2}, {1} ) )
    t:eq( true, c( {1, 2}, {1, 2} ) )
    t:eq( true, c( {1, 2, a=3}, {1, 2} ) )
    t:eq( true, c( {1, 2, a=3}, {1, 2, a=3} ) )

    t:eq( false, c( {1, 2, a=3}, {1, 2, b=3} ) )
    t:eq( false, c( {1, 2 }, {1, 2, b=3} ) )
    t:eq( false, c( {1}, {1, 2, b=3} ) )
    t:eq( false, c( {}, {1, 2, b=3} ) )

    t:eq( true, c( {1, 2, a={ x=1 }}, {1, 2} ) )
    t:eq( true, c( {1, 2, a={ x=1, y=2 }}, {1, 2, a={}} ) )
    t:eq( true, c( {1, 2, a={ x=1, y=2 }}, {1, 2, a={x=1}} ) )
    t:eq( true, c( {1, 2, a={ x=1, y=2 }}, {1, 2, a={x=1, y=2}} ) )

    t:eq( false, c( {1, 2, a={ x=1 }}, {1, 2, a={x=1, y=2}} ) )

    -- self reference
    local a = { x=1 }
    local b = { x=1 }

    a.self = { x=1 }
    b.self = {}
    t:eq( true, c( a, b ) )
    t:eq( false, c( b, a ) )

    a.self = a
    b.self = nil
    t:eq( true, c( a, b ) )
    t:eq( false, c( b, a ) )

    a.self = a
    b.self = b
    t:eq( true, c( a, b ) )
    t:eq( true, c( b, a ) )

    a.self = { self=a }
    b.self = nil
    t:eq( true, c( a, b ) )
    t:eq( false, c( b, a ) )

    a.self = { self=a, x=1 }
    b.self = b
    t:eq( true, c( a, b ) )

    a.self = { self={ self=a, x=1 }, x=1 }
    b.self = { self=b }
    t:eq( true, c( a, b ) )

    -- cross reference
    a.self = { x=1 }
    b.self = { x=1 }
    a.self.self = b
    b.self.self = a
    t:eq( true, c( a, b ) )
    t:eq( true, c( b, a ) )

end

function test.eq(t)
    local c = tableutil.eq
    t:eq( true, c( nil, nil ) )
    t:eq( true, c( 1, 1 ) )
    t:eq( true, c( "", "" ) )
    t:eq( true, c( "a", "a" ) )

    t:eq( false, c( 1, 2 ) )
    t:eq( false, c( 1, nil ) )
    t:eq( false, c( nil, 1 ) )
    t:eq( false, c( {}, 1 ) )
    t:eq( false, c( {}, "" ) )
    t:eq( false, c( "", {} ) )
    t:eq( false, c( 1, {} ) )

    t:eq( true, c( {}, {} ) )
    t:eq( true, c( {1}, {1} ) )
    t:eq( true, c( {1, 2}, {1, 2} ) )
    t:eq( true, c( {1, 2, a=3}, {1, 2, a=3} ) )

    t:eq( false, c( {1, 2}, {1} ) )
    t:eq( false, c( {1, 2, a=3}, {1, 2} ) )

    t:eq( false, c( {1, 2, a=3}, {1, 2, b=3} ) )
    t:eq( false, c( {1, 2 }, {1, 2, b=3} ) )
    t:eq( false, c( {1}, {1, 2, b=3} ) )
    t:eq( false, c( {}, {1, 2, b=3} ) )

    t:eq( true, c( {1, 2, a={ x=1, y=2 }}, {1, 2, a={x=1, y=2}} ) )

    t:eq( false, c( {1, 2, a={ x=1 }}, {1, 2, a={x=1, y=2}} ) )

    -- self reference
    local a = { x=1 }
    local b = { x=1 }

    a.self = { x=1 }
    b.self = {}
    t:eq( false, c( a, b ) )

    a.self = { x=1 }
    b.self = { x=1 }
    t:eq( true, c( a, b ) )

    a.self = a
    b.self = nil
    t:eq( false, c( b, a ) )

    a.self = a
    b.self = b
    t:eq( true, c( a, b ) )
    t:eq( true, c( b, a ) )

    a.self = { self=a }
    b.self = nil
    t:eq( false, c( a, b ) )

    a.self = { self=a, x=1 }
    b.self = b
    t:eq( true, c( a, b ) )

    a.self = { self={ self=a, x=1 }, x=1 }
    b.self = { self=b, x=1 }
    t:eq( true, c( a, b ) )

    -- cross reference
    a.self = { x=1 }
    b.self = { x=1 }
    a.self.self = b
    b.self.self = a
    t:eq( true, c( a, b ) )
    t:eq( true, c( b, a ) )

end


function test.cmp_list(t)

    for _, a, b, desc in t:case_iter(2, {
        {nil,           nil,           },
        {1,             true,          },
        {1,             '',            },
        {true,          true,          },
        {true,          nil,           },
        {{},            1,             },
        {{},            true,          },
        {{'a'},         {1},           },
        {{{'a'}},       {{1}},         },
        {function()end, function()end, },
        {function()end, 1,             },
    }) do

        t:err(function()
            tableutil.cmp_list(a, b)
        end, desc)
    end

    for _, a, b, expected, desc in t:case_iter(3, {
        {0,                 0,                 0  },
        {1,                 0,                 1  },
        {2,                 0,                 1  },
        {2,                 2,                 0  },
        {2,                 3,                 -1 },
        {'',                '',                0  },
        {'a',               'b',               -1 },
        {'c',               'b',               1  },
        {'foo',             'foo',             0  },
        {{},                {},                0  },
        {{1},               {},                1  },
        {{1},               {1},               0  },
        {{1,0},             {1},               1  },
        {{1,0},             {1,0},             0  },
        {{1,0},             {1,0,0},           -1 },
        {{'a'},             {'a',1},           -1 },
        {{'a',1,1},         {'a',1},           1  },
        {{'a',1,{'b'}},     {'a',1,{'b'}},     0  },
        {{'a',1,{'c'}},     {'a',1,{'b'}},     1  },
        {{'a',1,{'c',1}},   {'a',1,{'c',1}},   0  },
        {{'a',1,{'c',1,1}}, {'a',1,{'c',1}},   1  },
        {{'a',1,{'c',1}},   {'a',1,{'c',1,1}}, -1 },
        {{'a',1,{'c',1}},   {'a',1,{'c',2}},   -1 },
        {{'a',1,{'c',2}},   {'a',1,{'c',1}},   1  },
    }) do

        local rst = tableutil.cmp_list(a, b)
        dd('rst: ', rst)

        t:eq(expected, rst, desc)
    end
end


function test.intersection(t)
    local a = { a=1, 10 }
    local b = { 11, 12 }
    local c = tableutil.intersection( { a, b }, true )

    t:eq( 1, tableutil.nkeys( c ), 'c has 1' )
    t:eq( true, c[ 1 ] )

    local d = tableutil.intersection( { a, { a=20 } }, true )
    t:eq( 1, tableutil.nkeys( d ) )
    t:eq( true, d.a, 'intersection a' )

    local e = tableutil.intersection( { { a=1, b=2, c=3, d=4 }, { b=2, c=3 }, { b=2, d=5 } }, true )
    t:eq( 1, tableutil.nkeys( e ) )
    t:eq( true, e.b, 'intersection of 3' )

end

function test.union(t)
    local a = tableutil.union( { { a=1, b=2, c=3 }, { a=1, d=4 } }, 0 )
    t:eqdict( { a=0, b=0, c=0, d=0 }, a )
end

function test.mergedict(t)
    t:eqdict( { a=1, b=2, c=3 }, tableutil.merge( { a=1, b=2, c=3 } ) )
    t:eqdict( { a=1, b=2, c=3 }, tableutil.merge( {}, { a=1, b=2 }, { c=3 } ) )
    t:eqdict( { a=1, b=2, c=3 }, tableutil.merge( { a=1 }, { b=2 }, { c=3 } ) )
    t:eqdict( { a=1, b=2, c=3 }, tableutil.merge( { a=0 }, { a=1, b=2 }, { c=3 } ) )

    local a = { a=1 }
    local b = { b=2 }
    local c = tableutil.merge( a, b )
    t:eq( true, a==c )
    a.x = 10
    t:eq( 10, c.x )
end

function test.depth_iter(t)

    for _, _ in tableutil.depth_iter({}) do
        t:err( "should not get any keys" )
    end

    for ks, v in tableutil.depth_iter({1}) do
        t:eqdict( {1}, ks )
        t:eq( 1, v )
    end

    for ks, v in tableutil.depth_iter({a="x"}) do
        t:eqdict( {{"a"}, "x"}, {ks, v} )
    end

    local a = {
        1, 2, 3,
        { 1, 2, 3, 4 },
        a=1,
        c=100000,
        d=1,
        x={
            1,
            { 1, 2 },
            y={
                a=1,
                b=2
            }
        },
        ['fjklY*(']={
            x=1,
            b=3,
        },
        [100]=33333
    }
    a.z = a.x

    local r = {
        { {1}, 1 },
        { {100}, 33333 },
        { {2}, 2 },
        { {3}, 3 },
        { {4,1}, 1 },
        { {4,2}, 2 },
        { {4,3}, 3 },
        { {4,4}, 4 },
        { {"a"}, 1 },
        { {"c"}, 100000 },
        { {"d"}, 1 },
        { {"fjklY*(","b"}, 3 },
        { {"fjklY*(","x"}, 1 },
        { {"x",1}, 1 },
        { {"x",2,1}, 1 },
        { {"x",2,2}, 2 },
        { {"x","y","a"}, 1 },
        { {"x","y","b"}, 2 },
        { {"z",1}, 1 },
        { {"z",2,1}, 1 },
        { {"z",2,2}, 2 },
        { {"z","y","a"}, 1 },
        { {"z","y","b"}, 2 },
    }

    local i = 0
    for ks, v in tableutil.depth_iter(a) do
        i = i + 1
        t:eqdict( r[i], {ks, v} )
    end

end


function test.has(t)
    local cases = {
        {nil, {}, true},
        {1, {1}, true},
        {1, {1, 2}, true},
        {1, {1, 2, 'x'}, true},
        {'x', {1, 2, 'x'}, true},

        {1, {x=1}, true},

        {'x', {x=1}, false},
        {"x", {1}, false},
        {"x", {1, 2}, false},
        {1, {}, false},
    }

    for ii, c in ipairs(cases) do
        local val, tbl, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        t:eq(expected, tableutil.has(tbl, val))
    end
end


function test.remove_value(t)
    local t1 = {}
    local cases = {
        {{},                nil, {},                nil},
        {{1, 2, 3},         2,   {1, 3},            2},
        {{1, 2, 3, x=4},    2,   {1, 3, x=4},       2},
        {{1, 2, 3},         3,   {1, 2},            3},
        {{1, 2, 3, x=4},    3,   {1, 2, x=4},       3},
        {{1, 2, 3, x=4},    4,   {1, 2, 3},         4},
        {{1, 2, 3, x=t1},   t1,  {1, 2, 3},         t1},

        {{1, 2, t1, x=t1}, t1,   {1, 2, x=t1}, t1},
    }

    for i, case in ipairs(cases) do

        local tbl, val, expected_tbl, expected_rst = case[1], case[2], case[3], case[4]

        local rst = tableutil.remove_value(tbl, val)

        t:eqdict(expected_tbl, tbl, i .. 'th tbl')
        t:eq(expected_rst, rst, i .. 'th rst')
    end
end


function test.remove_all(t)
    local t1 = {}
    local cases = {
        {{},                   nil, {},                0},
        {{1,2,3},              2,   {1, 3},            1},
        {{1,2,3,x=4},          2,   {1, 3, x=4},       1},
        {{1,2,3,x=2},          2,   {1, 3},            2},
        {{1,2,3},              3,   {1, 2},            1},
        {{1,2,3,x=4},          3,   {1, 2, x=4},       1},
        {{1,2,3,4,x=4},        4,   {1, 2, 3},         2},
        {{1,t1,3,x=t1,y=t1},   t1,  {1, 3},            3},

        {{1,2,t1,x=t1},        t1,  {1, 2},            2},
    }

    for i, case in ipairs(cases) do

        local tbl, val, expected_tbl, expected_rst = case[1], case[2], case[3], case[4]

        local rst = tableutil.remove_all(tbl, val)

        t:eqdict(expected_tbl, tbl, i .. 'th tbl')
        t:eq(expected_rst, rst, i .. 'th rst')
    end
end


function test.get_random_elements(t)

    local cases = {
        {1,         nil,        1},
        {'123',     2,          '123'},
        {{},        nil,        {}},
        {{1},       nil,        {1}},
    }

    for ii, c in ipairs(cases) do
        local tbl, n, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = tableutil.random(tbl, n)
        t:eqdict(expected, rst, msg)
    end

    -- random continuous

    local expected = {
        {1, 2, 3},
        {2, 3, 1},
        {3, 1, 2}
    }

    local rst = tableutil.random({1, 2, 3}, nil)
    t:eqdict(expected[rst[1]], rst, 'rand {1, 2, 3}, nil')
end


function test.extends(t)

    for _, a, b, desc in t:case_iter(2, {
        {{'a'},         1,             },
        {{'a'},         'a',           },
        {{'a'},         function()end, },
    }) do

        t:err(function()
            tableutil.extends(a, b)
        end, desc)
    end

    for _, a, b, expected, desc in t:case_iter(3, {
        {{1,2},     {3,4},       {1,2,3,4}      },
        {{1,2},     {3},         {1,2,3}        },
        {{1,2},     {nil},       {1,2}          },
        {{1,2},     {},          {1,2}          },
        {{},        {1,2},       {1,2}          },
        {nil,       {1},         nil            },
        {{1,{2,3}}, {4,5},       {1,{2,3},4,5}  },
        {{1},       {{2,3},4,5}, {1,{2,3},4,5}  },
        {{"xx",2},  {3,"yy"},    {"xx",2,3,"yy"}},
        {{1,2},     {3,nil,4},   {1,2,3}        },
        {{1,nil,2}, {3,4},       {1,3,2,4}      },
    }) do

        local rst = tableutil.extends(a, b)

        dd('rst: ', rst)

        t:eqdict(expected, rst, desc)
    end
end


function test.is_empty(t)
    local cases = {
        {{}          , true},
        {{1}         , false},
        {{key='val'} , false},
    }

    for ii, c in ipairs(cases) do
        local tbl, expected = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = tableutil.is_empty(tbl)
        t:eq(expected, rst)
    end

    t:eq(false, tableutil.is_empty())
end


function test.get(t)

    local cases = {

        {nil,       '',          nil, 'NotFound'},
        {nil,       'a',         nil, 'NotFound'},
        {{},        'a',         nil, nil},
        {{},        'a.b',       nil, 'NotFound'},
        {{a=1},     '',          nil, nil},
        {{a=1},     'a',         1,   nil},
        {{a=1},     'a.b',       nil, 'NotTable'},
        {{a=true},  'a.b',       nil, 'NotTable'},
        {{a=""},    'a.b',       nil, 'NotTable'},
        {{a={b=1}}, 'a.b',       1,   nil},
        {{a={b=1}}, 'a.b.cc',    nil, 'NotTable' },
        {{a={b=1}}, 'a.b.cc.dd', nil, 'NotTable' },
        {{a={b=1}}, 'a.x.cc',    nil, 'NotFound' },

    }

    for ii, c in ipairs(cases) do
        local tbl, keys, expected_rst, expected_err = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst, err = tableutil.get(tbl, keys)

        t:eq(expected_rst, rst)
        t:eq(expected_err, err)

    end
end


function test.updatedict(t)

    local cases = {
        {{},            {},            nil,               {}                },
        {{a=1},         {},            nil,               {a=1}             },
        {{a=1},         {a=2},         nil,               {a=2}             },
        {{a=1},         {a=1,b=2},     nil,               {a=1,b=2}         },
        {{},            {a={b={c=1}}}, nil,               {a={b={c=1}}}     },
        {{a='foo'},     {a={b={c=1}}}, nil,               {a={b={c=1}}}     },
        {{a={}},        {a={b={c=1}}}, nil,               {a={b={c=1}}}     },
        {{1},           {a={b={c=1}}}, nil,               {1,a={b={c=1}}}   },
        {{b=1},         {a={b={c=1}}}, nil,               {b=1,a={b={c=1}}} },
        {{a=1},         {a=2},         {force=false},     {a=1}             },
        {{a={b=1}},     {a={b=2}},     {force=false},     {a={b=1}}         },
        {{a={b=1}},     {a=2},         {force=false},     {a={b=1}}         },
        {{a={b={c=1}}}, {a=2},         {recursive=false}, {a=2}             },
        {{a={b={c=1}}}, {a={}},        {recursive=false}, {a={}}            },
        {{a=1},         {a={}},        {recursive=false}, {a={}}            },
    }

    for ii, c in ipairs(cases) do
        local tbl, src, opts, expected_rst = t:unpack(c)
        local msg = 'case: ' .. tostring(ii) .. '-th '
        dd(msg, c)

        local rst = tableutil.update(tbl, src, opts)
        dd('rst:', rst)

        t:eqdict(expected_rst, rst)
    end

    local a = {}
    a.a1 = a
    a.a2 = a

    local b = tableutil.update({}, a)
    t:eq(b.a1, b.a1.a1, 'test loop reference')
    t:eq(b.a1, b.a2, 'two loop references should be equal')
    t:neq(a, b.a1)
end
