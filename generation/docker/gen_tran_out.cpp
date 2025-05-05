#define Kinetics_Parameters_csv 0
vector<string> name_file = {"Kinetics_Parameters.csv"};
vector<Table> class_files(1, Table());

double Reaction_1_general(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces, const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time) {
    double rate = function_1(Value, NumTrans, NumPlaces, NameTrans, Trans, T, time, class_files[Kinetics_Parameters_csv].getConstantFromList(0));
    return (rate);
}

double Reaction_2_general(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces, const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time) {
    double rate = function_2(Value, NumTrans, NumPlaces, NameTrans, Trans, T, time, class_files[Kinetics_Parameters_csv].getConstantFromList(1));
    return (rate);
}

