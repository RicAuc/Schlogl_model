
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
                  const double& time,
                  double k1_rate)
  
  {
  // Definition of the function exploited to calculate the rate,
  // in this case for semplicity we define it throught the Mass Action law
  
  double intensity = 1.0;
  
  double X = Value[Trans[T].InPlaces[0].Id];
  intensity = X * (X - 1);
  
  double rate = (k1_rate/2) * intensity;
  // 
  // cout << "k1 = " << k1_rate;
  // cout << "rate = " << rate;
  
  return(rate);
}

double F_k2(double *Value,
                  map <string,int>& NumTrans,
                  map <string,int>& NumPlaces,
                  const vector<string> & NameTrans,
                  const struct InfTr* Trans,
                  const int T,
                  const double& time,
                  double k2_rate)
  
{
  // Definition of the function exploited to calculate the rate,
  // in this case for simplicity we define it through the Mass Action law
  
  double intensity = 1.0;
  
  double X = Value[Trans[T].InPlaces[0].Id];
  intensity = X * (X - 1);
  
  double rate = (k2_rate/2) * intensity;
  
  // cout << "k2 = " << k2_rate;
  // cout << "rate = " << rate;
  
  return(rate);
}
