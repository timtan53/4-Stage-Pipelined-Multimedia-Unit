#include <iostream>
#include <fstream>
#include <string>

using namespace std;

string trim(string s) {
    int start = 0;
    int end = (int)s.length() - 1;

    while (start <= end && (s[start] == ' ' || s[start] == '\t')) {
        start++;
    }

    while (end >= start && (s[end] == ' ' || s[end] == '\t' || s[end] == '\r')) {
        end--;
    }

    if (start > end) return "";
    return s.substr(start, end - start + 1);
}

string lower_string(string s) {
    for (int i = 0; i < (int)s.length(); i++) {
        if (s[i] >= 'A' && s[i] <= 'Z') {
            s[i] = s[i] - 'A' + 'a';
        }
    }
    return s;
}

string remove_comment(string line) {
    int cut = -1;

    for (int i = 0; i < (int)line.length(); i++) {
        if (line[i] == '#') {
            cut = i;
            break;
        }

        if (i + 1 < (int)line.length() && line[i] == '/' && line[i + 1] == '/') {
            cut = i;
            break;
        }
    }

    if (cut == -1) return line;
    return line.substr(0, cut);
}

int tokenize(string line, string tokens[], int max_tokens) {
    int count = 0;
    string current = "";

    for (int i = 0; i < (int)line.length(); i++) {
        char c = line[i];

        if (c == ',' || c == ' ' || c == '\t') {
            if (current != "") {
                if (count < max_tokens) {
                    tokens[count] = current;
                    count++;
                }
                current = "";
            }
        } else {
            current += c;
        }
    }

    if (current != "") {
        if (count < max_tokens) {
            tokens[count] = current;
            count++;
        }
    }

    return count;
}

bool parse_number(string s, int &value) {
    s = trim(s);
    if (s == "") return false;

    int sign = 1;
    int i = 0;
    value = 0;

    if (s[0] == '-') {
        sign = -1;
        i = 1;
    }

    int base = 10;

    if (i + 1 < (int)s.length() && s[i] == '0' && (s[i + 1] == 'x' || s[i + 1] == 'X')) {
        base = 16;
        i += 2;
    }

    if (i >= (int)s.length()) return false;

    for (; i < (int)s.length(); i++) {
        char c = s[i];
        int digit;

        if (c >= '0' && c <= '9') {
            digit = c - '0';
        } else if (c >= 'a' && c <= 'f') {
            digit = c - 'a' + 10;
        } else if (c >= 'A' && c <= 'F') {
            digit = c - 'A' + 10;
        } else {
            return false;
        }

        if (digit >= base) return false;

        value = value * base + digit;
    }

    value *= sign;
    return true;
}

bool parse_register(string s, int &reg) {
    s = lower_string(trim(s));

    if (s.length() > 0 && s[0] == 'r') {
        s = s.substr(1);
    }

    if (!parse_number(s, reg)) return false;

    if (reg < 0 || reg > 31) return false;

    return true;
}

string bits(int value, int width) {
    string out = "";

    unsigned int mask;

    if (width == 32) {
        mask = 0xFFFFFFFF;
    } else {
        mask = (1u << width) - 1u;
    }

    unsigned int v = ((unsigned int)value) & mask;

    for (int i = width - 1; i >= 0; i--) {
        if ((v >> i) & 1u) {
            out += '1';
        } else {
            out += '0';
        }
    }

    return out;
}

string r4_subop(string op) {
    if (op == "simals") return "000";
    if (op == "simahs") return "001";
    if (op == "simsls") return "010";
    if (op == "simshs") return "011";
    if (op == "slmals") return "100";
    if (op == "slmahs") return "101";
    if (op == "slmsls") return "110";
    if (op == "slmshs") return "111";
    return "";
}

string r3_opcode(string op) {
    if (op == "nop")   return "0000";
    if (op == "shrhi") return "0001";
    if (op == "au")    return "0010";
    if (op == "cnt1h") return "0011";
    if (op == "ahs")   return "0100";
    if (op == "or")    return "0101";
    if (op == "bcw")   return "0110";
    if (op == "maxws") return "0111";
    if (op == "minws") return "1000";
    if (op == "mlhu")  return "1001";
    if (op == "mlhcu") return "1010";
    if (op == "and")   return "1011";
    if (op == "clzw")  return "1100";
    if (op == "rotw")  return "1101";
    if (op == "sfwu")  return "1110";
    if (op == "sfhs")  return "1111";
    return "";
}

bool assemble_li(string tokens[], int count, string &machine) {
    if (count != 4) return false;

    int rd, index, imm;

    if (!parse_register(tokens[1], rd)) return false;
    if (!parse_number(tokens[2], index)) return false;
    if (!parse_number(tokens[3], imm)) return false;

    if (index < 0 || index > 7) return false;
    if (imm < -32768 || imm > 65535) return false;

    machine = "";
    machine += "0";
    machine += bits(index, 3);
    machine += bits(imm, 16);
    machine += bits(rd, 5);

    return true;
}

bool assemble_r4(string tokens[], int count, string &machine) {
    if (count != 5) return false;

    string op = lower_string(tokens[0]);
    string subop = r4_subop(op);

    if (subop == "") return false;

    int rd, rs1, rs2, rs3;

    if (!parse_register(tokens[1], rd)) return false;
    if (!parse_register(tokens[2], rs1)) return false;
    if (!parse_register(tokens[3], rs2)) return false;
    if (!parse_register(tokens[4], rs3)) return false;

    machine = "";
    machine += "10";
    machine += subop;
    machine += bits(rs3, 5);
    machine += bits(rs2, 5);
    machine += bits(rs1, 5);
    machine += bits(rd, 5);

    return true;
}

bool assemble_r3(string tokens[], int count, string &machine) {
    string op = lower_string(tokens[0]);
    string opcode = r3_opcode(op);

    if (opcode == "") return false;

    int rd = 0;
    int rs1 = 0;
    int rs2_field = 0;

    if (op == "nop") {
        if (count != 1) return false;
    }
    else if (op == "shrhi") {
        if (count != 4) return false;

        if (!parse_register(tokens[1], rd)) return false;
        if (!parse_register(tokens[2], rs1)) return false;
        if (!parse_number(tokens[3], rs2_field)) return false;

        if (rs2_field < 0 || rs2_field > 31) return false;
    }
    else if (op == "cnt1h" || op == "bcw" || op == "clzw") {
        if (count != 3) return false;

        if (!parse_register(tokens[1], rd)) return false;
        if (!parse_register(tokens[2], rs1)) return false;

        rs2_field = 0;
    }
    else if (op == "mlhcu") {
        if (count != 4) return false;

        if (!parse_register(tokens[1], rd)) return false;
        if (!parse_register(tokens[2], rs1)) return false;
        if (!parse_number(tokens[3], rs2_field)) return false;

        if (rs2_field < 0 || rs2_field > 31) return false;
    }
    else {
        if (count != 4) return false;

        if (!parse_register(tokens[1], rd)) return false;
        if (!parse_register(tokens[2], rs1)) return false;
        if (!parse_register(tokens[3], rs2_field)) return false;
    }

    machine = "";
    machine += "11";
    machine += "0000";
    machine += opcode;
    machine += bits(rs2_field, 5);
    machine += bits(rs1, 5);
    machine += bits(rd, 5);

    return true;
}

bool assemble_line(string line, string &machine) {
    line = trim(remove_comment(line));

    if (line == "") {
        machine = "";
        return true;
    }

    string tokens[10];
    int count = tokenize(line, tokens, 10);

    if (count == 0) {
        machine = "";
        return true;
    }

    string op = lower_string(tokens[0]);

    if (op == "li") {
        return assemble_li(tokens, count, machine);
    }

    if (r4_subop(op) != "") {
        return assemble_r4(tokens, count, machine);
    }

    if (r3_opcode(op) != "") {
        return assemble_r3(tokens, count, machine);
    }

    return false;
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        cout << "Usage: assembler <input.asm> <output.txt>" << endl;
        return 1;
    }

    ifstream input(argv[1]);
    ofstream output(argv[2]);

    if (!input.is_open()) {
        cout << "Error: could not open input file." << endl;
        return 1;
    }

    if (!output.is_open()) {
        cout << "Error: could not open output file." << endl;
        return 1;
    }

    string line;
    int line_number = 0;

    while (getline(input, line)) {
        line_number++;

        string machine;

        if (!assemble_line(line, machine)) {
            cout << "Assembly error on line " << line_number << ": " << line << endl;
            return 1;
        }

        if (machine != "") {
            if (machine.length() != 25) {
                cout << "Internal error: instruction is not 25 bits on line " << line_number << endl;
                return 1;
            }

            output << machine << endl;
        }
    }

    cout << "Assembly completed successfully." << endl;
    return 0;
}