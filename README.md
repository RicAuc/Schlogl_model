## The Schlögl model: Reaction rate equation model

The Schlögl model is an example of a reaction network which exhibits bistability. A canonical bistable network demonstrates noise-induced switching impossible under deterministic dynamics. With species A and B held constant, the number of X molecules flips between two steady states in stochastic simulations, whereas ODEs remain trapped in one basin.

---
### Comparison table of Schlögl–model experimental settings

These variants emphasize both net structure and how kinetics are specified:

| Variant                           | Topology                                                                                     | Kinetics Specification                                                                                                           | Purpose / Notes                                                                              |
| --------------------------------- | -------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| **extended\_simple**              | 3 places (**X\_A**, **X1**, **X\_B**); 4 transitions coupling chemostat reservoirs to **X1** | Hard-coded numeric delays in the `.PNPRO`                                                   | Full Schlögl system with A/B reservoirs, showing how to model chemostats purely via PN files |
| **reduced\_simple**               | 1 place (**X1**); 4 core Schlögl transitions (2 X→3 X, 3 X→2 X, ∅→X, X→∅)                    | Hard-coded numeric delays in the `.PNPRO`                                                                                        | Minimal core network, all parameters embedded directly in the PN file                        |
| **reduced\_noCPP\_FromList**      | Same as **reduced\_simple**                                                                  | `FromList[...]` in PNPRO reads each k₁–k₄ value from an R list supplied at generation time                                       | Demonstrates injecting parameters from R (no compiled code)                                  |
| **reduced\_noCPP\_FromTable**     | Same as **reduced\_simple**                                                                  | `FromTable[...]` in PNPRO looks up k₁–k₄ in a CSV file at generation time                                                        | Pure R-side table-driven rates, still embedded in the PN definition                          |
| **reduced\_CPP\_Call\_FromTable** | Same as **reduced\_simple**                                                                  | Transitions k₁–k₂ invoke C++ (`Call[...]`) functions that themselves read from a CSV; k₃–k₄ use numeric delays                   | Hybrid: custom C++ for complex steps, plus table lookup for numeric values                   |
| **reduced\_alternative**          | Same as **reduced\_simple**                                                                  | All delays set to a dummy constant (`delay="1"`) in PNPRO; at analysis time an external `iniData` CSV supplies real k₁–k₄ values | Decouples net structure from data: defers full parameterization to the analysis phase        |

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
// F_k1: 2 X → 3 X (mass-action with combinatorial factor)
double F_k1(double *Value, Transition *Trans, int T, double k1_rate) {
  // Value[] holds current place markings; Trans[T].InPlaces[0].Id gives the index of X
  double X = Value[ Trans[T].InPlaces[0].Id ];
  double intensity = X * (X - 1);
  return (k1_rate / 2.0) * intensity;
}
```

> Rather than baking in simple numeric delays or basic table lookups, you can code arbitrarily complex formulas, branching logic, or even invoke external libraries here.

---

### 2. Integration via the `Call[…]` Directive

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

