import std.stdio: writeln;
import farfadet.startup;

void main(string[] args) {
    try {
        setupApplication(args);
    }
    catch(Exception e) {
        writeln(e.msg);
    }
}