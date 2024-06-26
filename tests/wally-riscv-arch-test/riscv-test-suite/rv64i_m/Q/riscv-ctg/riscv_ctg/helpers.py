import re

class ExtractException(Exception):
    pass

num_dict = {
        'rs1_val': '1',
        'rs2_val': '2',
        'rs3_val': '3',
}
fsub_vars = ['fe','fm','fs']

val_regex = "{0}\s*==\s*(?P<{1}>[0-9abcdefx+\-\*/\|\&]*)\s*"

def to_int(x):
    if '0x' in x:
        return int(x,16)
    else:
        return int(x)

def nan_box(prefix,rs,flen,iflen):
    if int(prefix) == ((2**(flen-iflen))-1):
        return (rs,iflen)
    else:
        return (str(to_int(rs)|(to_int(prefix)<<iflen)),flen)

def extract_frs_fields(reg,cvp,iflen):
    if (iflen == 32):
        e_sz = 8
        m_sz = 23
    elif (iflen == 64):
        e_sz = 11
        m_sz = 52
    else:
        e_sz = 15
        m_sz = 112
    s_sz_string = '{:01b}'
    e_sz_string = '{:0'+str(e_sz)+'b}'
    m_sz_string = '{:0'+str(m_sz)+'b}'
    size_string = '{:0'+str(int(iflen/4))+'x}'
    fvals = {}
    for var in fsub_vars:
        regex = val_regex.format(var+reg,var+reg)
        match_obj = re.search(regex,cvp)
        if match_obj is not None:
            fvals[var+reg] = eval(match_obj.group(var+reg))
        else:
            raise ExtractException("{0} not defined in coverpoint:{1}".format(var+reg,cvp))
    bin_val1 = s_sz_string.format(fvals['fs'+reg]) + e_sz_string.format(fvals['fe'+reg]) \
            + m_sz_string.format(fvals['fm'+reg])
    hex_val1 = '0x' + size_string.format(int(bin_val1, 2))
    return int(hex_val1,16)

def merge_fields_f(val_vars,cvp,flen,iflen,merge):
    nan_box = False
    if flen > iflen:
        nan_box = True
    fdict = {}
    for var in val_vars:
        if var in num_dict and merge:
            fdict[var] = extract_frs_fields(num_dict[var],cvp,iflen)
            if nan_box:
                nan_var = 'rs{0}_nan_prefix'.format(num_dict[var])
                regex = val_regex.format(nan_var.replace("_","\\_"),nan_var)
                match_obj = re.search(regex,cvp)
                if match_obj is not None:
                    fdict[nan_var] = eval(match_obj.group(nan_var))
                else:
                    fdict[nan_var] = (2**(flen-iflen))-1
        else:
            regex = val_regex.format(var.replace("_","\\_"),var)
            match_obj = re.search(regex,cvp)
            if match_obj is not None:
                fdict[var] = eval(match_obj.group(var))
            elif 'nan_prefix' not in var:
                raise ExtractException("{0} not defined in coverpoint:{1}".format(var,cvp))
    return fdict


