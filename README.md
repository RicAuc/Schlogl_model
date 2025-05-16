## The Schlögl model: Reaction rate equation model

The Schlögl model is an example of a reaction network which exhibits bistability. A canonical bistable network demonstrates noise-induced switching impossible under deterministic dynamics. With species A and B held constant, the number of X molecules flips between two steady states in stochastic simulations, whereas ODEs remain trapped in one basin.

# PNPRO Variants Documentation

Below is a summary of each `.PNPRO` model in the `net` directory. For each variant, we list its purpose, network topology, and how kinetics parameters are specified.

---

This repository provides six variations of the Schlögl reaction system, each illustrating a different way to specify kinetics in epimod:

## Extended_simple.PNPRO

This model captures the full Schlögl bistable network with three places—`X1` (the autocatalytic species), `X_A` (the A reservoir) and `X_B` (the B/C reservoir)—and four mass‐action transitions:

1. **2 X1 + X_A → 3 X1** 
2. **3 X1 → 2 X1 + X_A**
3. **X_B → X1**
4. **X1 → X_B**  

Each transition’s delay constant (0.03, 0.0001, 200, 3.5 respectively) is defined directly in the PNPRO file, so no external tables or code extensions are needed.

## Reduced_simple.PNPRO

Collapses A, B and C into effective birth/death rates for X alone:

- **X → 2 X** (birth)  
- **2 X → X** (death)  

The two rate constants (k₊, k₋) are pre-computed and embedded directly in the file, yielding a minimal autocatalysis/dissipation model.

## Reduced_alternative.PNPRO

This variant reinstates all core Schlögl reactions but externalizes every rate constant via epimod R function executing mechanism.

from `rfunctions.R` as the initial token count for the single place `X1` .

**Rate‐Law Loading**
  At generation time, epimod reads `input/iniData_reduced_alternative.csv`, which contains:

  ```
  m;X1;init.gen;
  c;k1;kinetic_parameters;file="/…/input/KineticsParameters.csv";n=1;
  c;k2;kinetic_parameters;file="/…/input/KineticsParameters.csv";n=2;
  c;k3;kinetic_parameters;file="/…/input/KineticsParameters.csv";n=3;
  c;k4;kinetic_parameters;file="/…/input/KineticsParameters.csv";n=4;
  ```

  ```r
  kinetic_parameters(file, n)
  ```

also in **rfunctions.R to read row *n* of `KineticsParameters.csv` (which holds the values and them as `delay` for transitions). 

This decoupling means you can tweak *any* of the four kinetic constants simply by editing `KineticsParameters.csv`—no changes to the Petri Net definition are required.

---

### Comparison table of Schlögl–model experimental settings

These variants emphasize both network topology and how kinetics are specified:

| Variant                         | Topology                                                           | Kinetics specification                                                                                                                        | Purpose / Notes                                                                              |
|---------------------------------|--------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| **extended_simple**             | 3 places (`X_A`, `X1`, `X_B`); 4 transitions coupling to `X1`      | Delay constants written directly as numeric `delay` attributes in the `.PNPRO`                                                                 | Canonical full-Schlögl model with A/B/C reservoirs defined purely in the Petri Net file     |
| **extended_CPP_Call**           | 3 places (`X_A`, `X1`, `X_B`); 4 transitions coupling to `X1`      | Each transition uses `Call[...]` to `functions/extended_general_functions.cpp`, computing mass-action rates in C++ with hard-coded constants    | Demonstrates custom C++ rate-law callbacks for the full Schlögl system                      |
| **reduced_simple**              | 1 place (`X1`); 4 core transitions                                 | Two effective rate constants embedded as fixed `delay` entries in the `.PNPRO`                                                                  | Minimal bistable network with all parameters embedded directly                               |
| **reduced_noCPP_FromList**      | 1 place (`X1`); 4 core transitions                                 | `<FromList>` in the PNPRO reads the four k₁–k₄ values at generation time from `input/iniData_reduced.csv` via `functions/rfunctions.R`          | Illustrates parameter injection from an external text file using epimod’s `FromList` loader  |
| **reduced_CPP_Call**            | 1 place (`X1`); 4 core transitions                                 | Each uses `Call[...]` to `functions/reduced_general_functions.cpp`, with k₁–k₄ passed in from `input/iniData_reduced.csv`                        | Integrates C++ rate-law callbacks consuming CSV-supplied parameters                          |
| **reduced_CPP_Call_FromTable**  | 1 place (`X1`); 4 core transitions                                 | Transitions call `functions/reduced_general_functions_from.cpp`, which reads parameters from `input/KineticsParameters.csv`; uses `rfunctions.R` | Combines table-driven parameter lookup with custom C++ callbacks, illustrating `FromTable`  |
| **reduced_alternative**         | 1 place (`X1`); 4 core transitions                                 | PNPRO sets all delays to `1`; at generation time `<FromList>` reads k₁–k₄ from `input/iniData_reduced_alternative.csv` via `functions/rfunctions.R` | Decouples network definition from kinetic data, deferring parameterization to analysis phase |
---

## Injecting Custom Kinetics via C++ in epimod

Files like `Schlogl_general_functions.cpp` serve to inject user-defined kinetic rate laws directly into the simulation engine. 

This approach gives:

* **Flexibility**: Any algorithmic rate law—beyond built-in mass-action is possible.
* **Performance**: Compiled C++ executes far faster than interpreted R.
* **Maintainability**: All “advanced” kinetics live in one place; editing `F_k2` is simpler than hunting through CSVs or PNPRO attributes.

---

### 1. Custom Rate Functions for Transitions

Each C++ function implements the propensity (rate) of a particular reaction in the Petri Net. For example, the autocatalytic step 2 X → 3 X:

```cpp
double F_k1(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces,
                  const vector<string> & NameTrans, const struct InfTr* Trans,
                  const int T, const double& time, double k1_rate)
  {
  
  double intensity = 1.0;
  double X = Value[Trans[T].InPlaces[0].Id];
  intensity = X * (X - 1);
  double rate = (k1_rate/2) * intensity;
  
  return(rate);
}

double F_k2(double *Value, map <string,int>& NumTrans, map <string,int>& NumPlaces,
                  const vector<string> & NameTrans, const struct InfTr* Trans,
                  const int T, const double& time, double k2_rate)
  {
  
  double intensity = 1.0;
  double X = Value[Trans[T].InPlaces[0].Id];
  intensity = X * (X - 1) * (X - 2);
  double rate = (k2_rate/6) * intensity;
  
  return(rate);
}
```

> Rather than baking in simple numeric delays or basic table lookups, you can code arbitrarily complex formulas, branching logic, or even invoke external libraries here.

---

### Integration via the `Call[…]` Directive

In the `.PNPRO` definition, we hook in each C++ function with a `Call` directive:

```text
transition k1 {
  InPlaces    = X1:2
  OutPlaces   = X1:3
  delay       = "Call[\"F_k1\", FromTable[\"KineticsParameters.csv\", 0, 0]]"
}
```

* **Declaration**

`Call["F_k1", …]` tells epimod to use your `F_k1` function.

* **Compilation**

   ```r
   model.generation(
     net_fname         = "net/reduced_CPP_Call_FromTable.PNPRO",
     transitions_fname = "functions/Schlogl_general_functions.cpp"
   )
   ```

 Epimod’s Docker build compiles auto-generated stubs and C++ file into a single `.solver` binary.

* **Runtime Invocation**
   During `model.analysis()`, the solver calls:

   ```cpp
   rate = F_k1(Value, Trans, T, k1_rate);
   ```

   to compute each reaction’s propensity.

C++ files are the bridge that lets you “call out” to custom, compiled code for any reaction’s kinetics. This approach combines expressiveness, speed, and maintainability in the automated epimod‐generated solver.

