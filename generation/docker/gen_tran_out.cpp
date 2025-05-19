vector<string> name_file = {};
double k2_general(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces, const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time) {
    double rate = F_k2(Value, NumTrans, NumPlaces, NameTrans, Trans, T, time);
    return (rate);
}

double k1_general(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces, const vector<string> & NameTrans, const struct InfTr* Trans, const int T, const double& time) {
    double rate = F_k1(Value, NumTrans, NumPlaces, NameTrans, Trans, T, time);
    return (rate);
}

