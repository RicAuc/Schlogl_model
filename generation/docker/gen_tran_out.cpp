#define KineticsParameters 0
vector<string> name_file = {"KineticsParameters"};
vector<Table> class_files(1, Table());

double k1_general(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces, const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time) {
    double rate = class_files[KineticsParameters].getConstantFromList(0);
    return (rate);
}

double k2_general(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces, const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time) {
    double rate = class_files[KineticsParameters].getConstantFromList(1);
    return (rate);
}

double k3_general(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces, const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time) {
    double rate = class_files[KineticsParameters].getConstantFromList(2);
    return (rate);
}

double k4_general(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces, const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time) {
    double rate = class_files[KineticsParameters].getConstantFromList(3);
    return (rate);
}

