#define KineticsParameters_csv 0
vector<string> name_file = {"KineticsParameters.csv"};
vector<Table> class_files(1, Table());

double k1_general(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces, const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time) {
    double rate = F_k1(Value, NumTrans, NumPlaces, NameTrans, Trans, T, time, class_files[KineticsParameters_csv].getConstantFromTable(0,0));
    return (rate);
}

double k2_general(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces, const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time) {
    double rate = F_k2(Value, NumTrans, NumPlaces, NameTrans, Trans, T, time, class_files[KineticsParameters_csv].getConstantFromTable(1,0));
    return (rate);
}

