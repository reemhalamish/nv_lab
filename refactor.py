import os
import sys
import colorama
import tempfile


TMP_FILE = os.path.join(tempfile.gettempdir(), 'temp_refactor_nv_lab.txt')



USAGE = '''
usage: refactor.py [-LF or --list-functions] [-M or --manual] <class_name> [<new_class_name> [-A or --actual]]
without using the actual,
it will only COUNT the amount
of times that <old_class_name> appeared

examples:

$[GREEN]refactor.py -M
    this will open a msgbox to insert the ocourence to look for

$[GREEN]refactor.py Physics$[WHITE]
    this will count the amount of times 'Physics' were found

$[GREEN]refactor.py Physics Physical$[WHITE]
    this will count the amount of times 'Physics' were found

$[GREEN]refactor.py Physics Physical -A$[WHITE]
    this will replace 'Physics' with 'Physical' everywhere

$[GREEN]refactor.py -LF$[WHITE]
    this will search for all the functions defined in the filename (prompt for input)

$[GREEN]refactor.py -LF ClassStage$[WHITE]
    this will search for all the functions defined in the file ClassStage    
'''

def print_usage():
    usage = ""
    in_color_read = False
    color = ""
    for letter in USAGE:
        if in_color_read:
            color += letter
            if color == '[GREEN]':
                print(colorama.Fore.GREEN)
                in_color_read = False
            elif color == '[WHITE]':
                print(colorama.Fore.WHITE)
                in_color_read = False
            continue
        if letter == '$':
            print(usage, end = '')
            in_color_read = True
            color = ""
            usage = ""
        else:
            usage += letter
    print()
            

def to_full_path(root, file):
    return os.path.join(root, file)
    


def find(prev_word, new_word='', actually_replace=False):
    os.chdir('.')
    total_counts = 0
    for root, folders, files in os.walk('.'):
        for file in files:
            found_in_file = False
            if not file.endswith('.m'):
                continue
            if prev_word in file:
                print(colorama.Fore.GREEN, 'in filename: ', colorama.Fore.RED, file, colorama.Fore.WHITE, sep='')
                total_counts += 1
                found_in_file = True

            with open(to_full_path(root, file), "rt") as old:
                with open(TMP_FILE, "wt") as tmp:
                    for line in old:
                        tmp.write(line.replace(prev_word, new_word))
                        if prev_word in line:
                            total_counts += line.count(prev_word)
                            if not found_in_file:
                                print('in file --- ', colorama.Fore.RED, file, colorama.Fore.WHITE, sep='')
                            found_in_file = True
                            line_colored = line.replace(prev_word, colorama.Fore.CYAN + prev_word + colorama.Fore.WHITE)
                            print(line_colored)

            if actually_replace:
                new_file = file.replace(prev_word, new_word)
                with open(TMP_FILE, "rt") as tmp:
                    with open(to_full_path(root, new_file), "wt") as new:
                        for line in tmp:
                            new.write(line)
                if prev_word in file:
                    # delete the original file
                    os.remove(to_full_path(root, file))

            if found_in_file:
                print('')

    os.remove(TMP_FILE)
    print('')
    print('~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*')
    print('')
    print('total:', total_counts)


def list_functions(filename_search):
    os.chdir('.')
    for root, folders, files in os.walk('.'):
        for filename in files:
            if filename_search not in filename:
                continue
            print(colorama.Fore.GREEN, filename, colorama.Fore.WHITE, sep='')
            
            with open(to_full_path(root, filename), "rt") as old:
                for line in old:
                    if 'methods' in line or 'function' in line:
                        line = line.replace('\n', '')
                        if '%' in line:
                            line = line[:line.find('%')]
                        if '...' in line:
                            line = line[:line.find('...')]
                        print(line)

def main(args):
    colorama.init(autoreset=False)
    if len(args) == 1:
        arg = args[0]
        if arg in ['-m', '-M', '--manual']:
            first = input('what to look for?\n')
            if not first:
                return
            second = input('press enter, or insert a replacement\n')
            if second:
                find(first, second, actually_replace=True)
            else:
                find(first)
        elif arg in ['-LF', '--list-functions']:
            filename_search = input('listing all functions in file. file name? ')
            list_functions(filename_search)
            
        else:
            find(args[0])
        return

    if len(args) == 2:
        if args[0] in ['-LF', '--list-functions']:
            list_functions(args[1])
            return

        if args[1] in ['-LF', '--list-functions']:
            list_functions(args[0])
            return
        
        find(args[0])
        _ = input('press enter to exit...')
        return

    if len(args) == 3 and args[2] in {'-A', '--actual'}:
        find(args[0], args[1], actually_replace=True)
        _ = input('press enter to exit...')
        return


    print_usage()
    _ = input('press enter to exit...')
    return
                    



main(sys.argv[1:])
    
