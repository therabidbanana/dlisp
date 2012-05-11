class O_o < StandardError; end
# Break string into tokens - note the ending parens can be sloppy
# we don't properly count them
def parse(string)
  tokens = string.is_a?(Array) ? string : string.gsub(/([\(\)])/,' \1 ').split
  list = nil; t = tokens.shift
  while t != ')' && !tokens.empty?
    case t when '(';ts = parse(tokens); list ? list << ts : list = ts; else list ||= []; list << atomize(t) end
    t = tokens.shift
  end
  list
end
# Parse nums, otherwise symbol
def atomize(i)
  ret = Integer(i);rescue;begin;ret ||= Float(i);rescue;ret ||= i.to_sym; end
end
def call(x, env=new_env)
  # Simple returns
  return env[x] if x.is_a?(Symbol)
  return x unless x.is_a?(Array)
  # Break list out, get first three expressions
  (atom,b,c) = x;
  # quote instantly returns b
  case atom when :quote; b;
  # define - calls c before storing as b
  when :define; env[b] = call(c, env); nil
  # Set only if b defined, always nil return
  when :set!; env[b, call(c,env)]; nil
  # (a, *b) = x for pulling off first atom; then call all expressions; get last
  when :begin;  (a, *d) = x; d.map{|exp| call(exp, env) }.last
  # return anonymous function
  when :lambda; (->(*args){call(c, new_env(b, args, env)) })
  # define last, eval either c or last depending on eval of b
  when :if; alt = x.last; call(call(b, env) ? c : alt, env)
  else
    # Pull out initial procedure name and then call it with list of args evaled
    (n, *d) = x.map{|exp| call(exp, env)}; n[*d]
  end
end
class Env
  attr_accessor :parent, :data
  def initialize(keys, vals, outer_env = nil)
    outer_env ||= global_env
    @parent = outer_env; @data = {}
    keys.each_with_index{|d, i| @data[d] = vals[i]  }
  end
  def [](k, set_if = nil)
    if set_if
      @data.has_key?(k) ? self[k]=set_if : (@parent[k, set_if] if @parent)
    else
      @data.has_key?(k) ? @data[k] : (@parent[k] if @parent)
    end
  end

  def []=(k,v); @data[k] = v; end
end
def new_env(*args); (a,b,c)=args; a||=[]; b||=[]; Env.new(a,b,c); end
def global_env
  glob = {
    :+ => ->(a,b){a+b}, :* => ->(a,b){a*b}, :-   => ->(a,b){a-b}, :/ => ->(a,b){a/b},
    :> => ->(a,b){a>b}, :< => ->(a,b){a<b}, :'=' => ->(a,b){a==b},
    :>= => ->(a,b){a>=b}, :<= => ->(a,b){a<=b},
  }
  Env.new(glob.keys,glob.values,{})
end

puts call(parse("(begin (define area_circ (lambda (r) (* 3.141592653 (* r r))))(if (> 1 0) (area_circ 3) (quote (0))))")).inspect
