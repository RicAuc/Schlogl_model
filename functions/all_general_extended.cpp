
// Import libraries and header files
#include <string.h>
#include <sys/resource.h>
#include <map>
#include <regex>
#include <iostream>
#include <fstream>
#include <cstdio>
#include <string>
#include <sstream>
#include <cmath>
#include <iomanip>    // Include for formatting output

double F_k1(double *Value,
                  map <string,int>& NumTrans,
                  map <string,int>& NumPlaces,
                  const vector<string> & NameTrans,
                  const struct InfTr* Trans,
                  const int T,
                  const double& time)
  
  {
  // Definition of the function exploited to calculate the rate,
  // in this case for semplicity we define it throught the Mass Action law
  
  double k1_rate = 0.0000003;
  double intensity = 1.0;
  
  double X_A = Value[Trans[T].InPlaces[0].Id];
  double X_1 = Value[Trans[T].InPlaces[1].Id];
  
  intensity = X_1 * (X_1 - 1) * X_A;
  
  double rate = (k1_rate/2) * intensity;
  
  cout << "### transition 1 firing ###" << "\n";
  
  cout << "X_A = " << X_A <<  "\n";
  cout << "X_1 = " << X_1 << "\n";
  
  cout << "k1 = " << k1_rate << "\n";
  cout << "intensity (f k1) = " << intensity << "\n";
  cout << "rate = " << rate << "\n";
  
  return(rate);
}

double F_k2(double *Value,
                  map <string,int>& NumTrans,
                  map <string,int>& NumPlaces,
                  const vector<string> & NameTrans,
                  const struct InfTr* Trans,
                  const int T,
                  const double& time)
  
{
  // Definition of the function exploited to calculate the rate,
  // in this case for simplicity we define it through the Mass Action law
  
  double k2_rate = 0.0001;
  double intensity = 1.0;
  double X_1 = Value[Trans[T].InPlaces[0].Id];
  
  intensity = X_1 * (X_1) * (X_1 - 2);
  
  double rate = (k2_rate/6) * intensity;
  
  cout << "### transition 2 firing ###" << "\n";

  cout << "X_1 = " << X_1 << "\n";
  cout << "k2 = " << k2_rate << "\n";
  cout << "intensity (f k2) = " << intensity << "\n";
  cout << "rate = " << rate << "\n";
  
  return(rate);
}

double F_k3(double *Value,
                  map <string,int>& NumTrans,
                  map <string,int>& NumPlaces,
                  const vector<string> & NameTrans,
                  const struct InfTr* Trans,
                  const int T,
                  const double& time) 
                  
{

  double k3_rate = 0.001;
  double X_B = Value[Trans[T].InPlaces[0].Id];
  double rate = (k3_rate) * X_B;
  
  cout << "### transition 3 firing ###" << "\n";

  cout << "X_B = " << X_B << "\n";
  cout << "k3 = " << k3_rate << "\n";
  cout << "rate (transition 3) = " << rate << "\n";
  
  return(rate); 
                  
}

double F_k4(double *Value,
                  map <string,int>& NumTrans,
                  map <string,int>& NumPlaces,
                  const vector<string> & NameTrans,
                  const struct InfTr* Trans,
                  const int T,
                  const double& time) 
                  
{

  double k4_rate = 3.5;

  double X_1 = Value[Trans[T].InPlaces[0].Id];
  
  double rate = (k4_rate) * X_1;
  
  cout << "### transition 4 firing ###" << "\n";

  cout << "X_1 = " << X_1 << "\n";
  cout << "k4 = " << k4_rate << "\n";
  cout << "rate (transition 4) = " << rate << "\n";
  
  return(rate); 
                  
}