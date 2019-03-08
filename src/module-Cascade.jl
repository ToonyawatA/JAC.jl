
"""
`module  JAC.Atomic`  ... a submodel of JAC that contains all methods to set-up and process (simple) atomic cascade computations; it is 
                          using JAC, JAC.Radial, JAC.ManyElectron, JAC.Nuclear.
"""
module Cascade

    using Printf, JAC, JAC.Radial, JAC.ManyElectron, JAC.Nuclear


    """
    `@enum   Cascade.Approach`  ... defines a enumeration for the computational approach/model that is applied to generate and evaluate a cascade.

        + averageSCA   ... to evaluate the level structure and transitions of all involved levels in single-configuration approximation.
                           In this approach, moreover, ... now tell further limitations.
    """
    @enum   Approach    averageSCA


    """
    `struct  Cascade.Block`  ... defines a type for an individual block of configurations that are treatet together within the cascade. 
                                 Such an block is given by a list of configurations that may occur as initial- or final-state configurations in some
                                 step of the canscade and that are treated together in a single multiplet to allow for configuration interaction 
                                 but to avoid 'double counting' of individual levels.

        + NoElectrons     ::Int64                     ... Number of electrons in this block.
        + confs           ::Array{Configuration,1}    ... List of one or several configurations that define the multiplet.
        + hasMultiplet    ::Bool                      ... true if the (level representation in the) multiplet has already been computed and
                                                          and false otherwise.
        + multiplet       ::Multiplet                 ... Multiplet of the this block.
    """
    struct  Block
        NoElectrons       ::Int64
        confs             ::Array{Configuration,1} 
        hasMultiplet      ::Bool
        multiplet
    end 


    """
    `JAC.Cascade.Block()`  ... constructor for an 'empty' instance of a Cascade.Block.
    """
    function Block()
        Block( )
    end


    """
    `Base.show(io::IO, block::Cascade.Block)`  ... prepares a proper printout of the variable block::Cascade.Block.
    """
    function Base.show(io::IO, block::Cascade.Block) 
        println(io, "NoElectrons:        $(block.NoElectrons)  ")
        println(io, "confs :             $(block.confs )  ")
        println(io, "hasMultiplet:       $(block.hasMultiplet)  ")
        println(io, "multiplet:          $(block.multiplet)  ")
    end


    """
    `struct  Cascade.Step`  ... defines a type for an individual step of an excitation and/or decay cascade. Such an individual step is given
                                by a well-defined process, such as AugerX, RadiativeX, or others and two lists of initial- and final-state 
                                configuration that are (each) treated together in a multiplet to allow for configuration interaction but 
                                to avoid 'double counting' of individual levels.

        + process          ::JAC.AtomicProcess         ... Atomic process that 'acts' in this step of the cascade.
        + initialConfs     ::Array{Configuration,1}    ... List of one or several configurations that define the initial-state 
                                                           multiplet of this step.
        + finalConfs       ::Array{Configuration,1}    ... List of one or several configurations that define the final-state multiplet.
        + hasMultiplets    ::Bool                      ... true if the (level represenation in the) multiplets are already computed/included,
                                                           and false otherwise (usually during the set-up and refinement of a cascade).
        + initialMultiplet ::Multiplet                 ... Multiplet of the initial-state levels of this step of the cascade.
        + finalMultiplet   ::Multiplet                 ... Multiplet of the final-state levels of this step of the cascade.
    """
    struct  Step
        process            ::JAC.AtomicProcess
        initialConfs       ::Array{Configuration,1}
        finalConfs         ::Array{Configuration,1}
        hasMultiplets      ::Bool
        initialMultiplet   ::Multiplet
        finalMultiplet     ::Multiplet
    end 


    """
    `JAC.Cascade.Step()`  ... constructor for an 'empty' instance of a Cascade.Step.
    """
    function Step()
        Step( )
    end


    """
    `Base.show(io::IO, step::Cascade.Step)`  ... prepares a proper printout of the variable step::Cascade.Step.
    """
    function Base.show(io::IO, step::Cascade.Step) 
        println(io, "process:                $(step.process)  ")
        println(io, "initialConfs:           $(step.initialConfs)  ")
        println(io, "finalConfs:             $(step.finalConfs)  ")
        println(io, "hasMultiplets:          $(step.hasMultiplets)  ")
        println(io, "initialMultiplet :      $(step.initialMultiplet )  ")
        println(io, "finalMultiplet:         $(step.finalMultiplet)  ")
    end


    """
    `struct  Cascade.Computation`  ... defines a type for a cascade computation, i.e. for the computation of a whole excitation and/or decay 
                                       cascade. The data from this computation can be modified, adapted and refined to the practical needs 
                                       before the actual computations are carried out. Initially, this struct contains the physical metadata 
                                       about the cascade to be calculated but gets enlarged in course of the computation to keep also wave 
                                       functions, level multiplets, etc.

        + name               ::String                         ... A name for the cascade
        + nuclearModel       ::Nuclear.Model           ... Model, charge and parameters of the nucleus.
        + grid               ::Radial.Grid                    ... The radial grid to be used for the computation.
        + asfSettings        ::AsfSettings                    ... Provides the settings for the SCF process.
        + approach           ::Cascade.Approach               ... Computational approach/model that is applied to generate and evaluate the 
                                                                  cascade; possible approaches are: {'single-configuration', ...}
        + processes          ::Array{JAC.AtomicProcess,1}     ... List of the atomic processes that are supported and should be included into the 
                                                                  cascade.
        + initialConfs       ::Array{Configuration,1}         ... List of one or several configurations that contain the level(s) from which the 
                                                                  cascade starts.
        + initialLevels      ::Array{Tuple{Int64,Float64},1}  ... List of one or several (tupels of) levels together with their relative population 
                                                                  from which the cascade starts.
        + maxElectronLoss    ::Int64                          ... (Maximum) Number of electrons in which the initial- and final-state 
                                                                  configurations can differ from each other; this also determines the maximal steps 
                                                                  of any particular decay path.
        + NoShakeDisplacements ::Int64                        ... Maximum number of electron displacements due to shake-up or shake-down processes 
                                                                  in any individual step of the cascade.
        + shakeFromShells ::Array{Shell,1}                    ... List of shells from which shake transitions may occur.
        + shakeToShells   ::Array{Shell,1}                    ... List of shells into which shake transitions may occur.
        + steps           ::Array{Cascade.Step,1}             ... List of individual steps between well-defined atomic multiplets that are 
                                                                  included into the cascade.
    """
    struct  Computation
        name                 ::String
        nuclearModel         ::Nuclear.Model
        grid                 ::Radial.Grid
        asfSettings          ::AsfSettings
        approach             ::Cascade.Approach
        processes            ::Array{JAC.AtomicProcess,1}
        initialConfs         ::Array{Configuration,1}
        initialLevels        ::Array{Tuple{Int64,Float64},1}
        maxElectronLoss      ::Int64
        NoShakeDisplacements ::Int64
        shakeFromShells      ::Array{Shell,1}
        shakeToShells        ::Array{Shell,1}
        steps                ::Array{Cascade.Step,1}
    end 


    """
    `JAC.Cascade.Computation()`  ... constructor for an 'empty' instance of a Cascade.Computation.
    """
    function Computation()
        Computation("",  Nuclear.Model(0.), Radial.Grid(), AsfSettings(), averageSCA, [AugerX], 
                    Configuration[], [(0, 0.)], 0, 0, Shell[], Shell[], CascadeComputationStep[] )
    end


    """
    `Base.show(io::IO, computation::Cascade.Computation)`  ... prepares a proper printout of the variable computation::Cascade.Computation.
    """
    function Base.show(io::IO, computation::Cascade.Computation) 
        println(io, "name:                     $(computation.name)  ")
        println(io, "nuclearModel:             $(computation.nuclearModel)  ")
        println(io, "grid:                     $(computation.grid)  ")
        println(io, "asfSettings:                computation.asfSettings  ")
        println(io, "approach:                 $(computation.approach)  ")
        println(io, "processes:                $(computation.processes)  ")
        println(io, "initialConfs:             $(computation.initialConfs)  ")
        println(io, "initialLevels:            $(computation.initialLevels)  ")
        println(io, "maxElectronLoss:          $(computation.maxElectronLoss)  ")
        println(io, "NoShakeDisplacements:     $(computation.NoShakeDisplacements)  ")
        println(io, "shakeFromShells:          $(computation.shakeFromShells)  ")
        println(io, "shakeToShells:            $(computation.shakeToShells)  ")
        println(io, "steps:                    $(computation.steps)  ")
    end


    """
    `struct  Cascade.Data`  ... defines a type for an atomic cascade, i.e. lists of radiative, Auger and photoionization lines.

        + name           ::String                               ... A name for the cascade.
        + linesR         ::Array{Radiative.Line,1}              ... List of radiative lines.
        + linesA         ::Array{Auger.Line,1}                  ... List of Auger lines.
        + linesP         ::Array{PhotoIonization.Line,1}        ... List of photoionization lines.
    """  
    struct  Data
        name             ::String
        linesR           ::Array{Radiative.Line,1}
        linesA           ::Array{Auger.Line,1}
        linesP           ::Array{PhotoIonization.Line,1}
    end 


    """
    `JAC.Cascade.Data()`  ... (simple) constructor for cascade data.
    """
    function Data()
        Data("", Array{Radiative.Line,1}[], Array{Auger.Line,1}[], Array{PhotoIonization.Line,1}[] )
    end


    """
    `Base.show(io::IO, data::Cascade.Data)`  ... prepares a proper printout of the variable data::Cascade.Data.
    """
    function Base.show(io::IO, data::Cascade.Data) 
        println(io, "name:                    $(data.name)  ")
        println(io, "linesR:                  $(data.linesR)  ")
        println(io, "linesA:                  $(data.linesA)  ")
        println(io, "linesP:                  $(data.linesP)  ")
    end


    """
    `@enum   Cascade.Property`  ... defines a enumeration for the various properties that can be obtained from the simulation of cascade data.

        + IonDist               ... simulate the 'ion distribution' as it is found after all cascade processes are completed.
        + FinalDist             ... simulate the 'final-level distribution' as it is found after all cascade processes are completed.
        + DecayPathes           ... determine the major 'decay pathes' of the cascade.
        + ElectronIntensity     ... simulate the electron-line intensities as function of electron energy.
        + PhotonIntensity       ... simulate  the photon-line intensities as function of electron energy. 
        + ElectronCoincidence   ... simulate electron-coincidence spectra.
    """
    @enum   Property    IonDist  FinalDist  DecayPathes  ElectronIntensity  PhotonIntensity  ElectronCoincidence


    """
    `@enum   Cascade.SimulationMethod`  ... defines a enumeration for the various methods that can be used to run the simulation of cascade data.

        + ProbPropagation     ... to propagate the (occupation) probabilites of the levels until no further changes occur.
        + MonteCarlo          ... to simulate the cascade decay by a Monte-Carlo approach of possible pathes (not yet considered).
        + RateEquations       ... to solve the cascade by a set of rate equations (not yet considered).
    """
    @enum   SimulationMethod    ProbPropagation   MonteCarlo  RateEquations


    """
    `struct  Cascade.SimulationSettings`  ... defines settings for performing the simulation of some cascade (data).

        + minElectronEnergy ::Float64     ... Minimum electron energy for the simulation of electron spectra.
        + maxElectronEnergy ::Float64     ... Maximum electron energy for the simulation of electron spectra.
        + minPhotonEnergy   ::Float64     ... Minimum photon energy for the simulation of electron spectra.
        + maxPhotonEnergy   ::Float64     ... Maximum photon energy for the simulation of electron spectra..
    """
    struct  SimulationSettings
        minElectronEnergy   ::Float64
        maxElectronEnergy   ::Float64
        minPhotonEnergy     ::Float64
        maxPhotonEnergy     ::Float64
    end 


    """
    `JAC.Cascade.SimulationSettings()`  ... constructor for an 'empty' instance of a Cascade.Block.
    """
    function SimulationSettings()
        SimulationSettings(0., 1.0e6,  0., 1.0e6 )
    end


    """
    `Base.show(io::IO, settings::SimulationSettings)`  ... prepares a proper printout of the variable settings::SimulationSettings.
    """
    function Base.show(io::IO, settings::SimulationSettings) 
        println(io, "minElectronEnergy:        $(settings.minElectronEnergy)  ")
        println(io, "maxElectronEnergy:        $(settings.maxElectronEnergy)  ")
        println(io, "minPhotonEnergy:          $(settings.minPhotonEnergy)  ")
        println(io, "maxPhotonEnergy:          $(settings.maxPhotonEnergy)  ")
    end


    """
    `struct  Cascade.Simulation`  ... defines a simulation on some given cascade (data).

        + properties      ::Array{Cascade.Property,1}   ... Properties that are considered in this simulation of the cascade (data).
        + method          ::Cascade.SimulationMethod    ... Method that is used in the cascade simulation; cf. Cascade.SimulationMethod.
        + settings        ::Cascade.SimulationSettings  ... Settings for performing these simulations.
    """
    struct  Simulation
        properties        ::Array{Cascade.Property,1}
        method            ::Cascade.SimulationMethod
        settings          ::Cascade.SimulationSettings
    end 


    """
    `Base.show(io::IO, simulation::Cascade.Simulation)`  ... prepares a proper printout of the variable simulation::Cascade.Simulation.
    """
    function Base.show(io::IO, simulation::Cascade.Simulation) 
        println(io, "properties:        $(simulation.properties)  ")
        println(io, "method:            $(simulation.method)  ")
        println(io, "settings:          $(simulation.settings)  ")
    end


    """
    `struct  Cascade.LineIndex`  ... defines a line index with regard to the various lineLists of data::Cascade.Data.

        + process      ::JAC.AtomicProcess    ... refers to the particular lineList of cascade (data).
        + index        ::Int64                ... index of the corresponding line.
    """
    struct  LineIndex
        process        ::JAC.AtomicProcess
        index          ::Int64 
    end 


    """
    `Base.show(io::IO, index::Cascade.LineIndex)`  ... prepares a proper printout of the variable index::Cascade.LineIndex.
    """
    function Base.show(io::IO, index::Cascade.LineIndex) 
        println(io, "process:        $(index.process)  ")
        println(io, "index:          $(index.index)  ")
    end


    """
    `mutable struct  Cascade.Level`  ... defines a level specification for dealing with cascade transitions.

        + energy       ::Float64                     ... energy of the level.
        + J            ::AngularJ64                  ... total angular momentum of the level
        + parity       ::JAC.Parity                  ... total parity of the level
        + NoElectrons  ::Int64                       ... total number of electrons of the ion to which this level belongs.
        + relativeOcc  ::Float64                     ... relative occupation  
        + parents      ::Array{Cascade.LineIndex,1}  ... list of parent lines that (may) populate the level.     
        + daugthers    ::Array{Cascade.LineIndex,1}  ... list of daugther lines that (may) de-populate the level.     
    """
    mutable struct  Level
        energy         ::Float64 
        J              ::AngularJ64 
        parity         ::JAC.Parity 
        NoElectrons    ::Int64 
        relativeOcc    ::Float64 
        parents        ::Array{Cascade.LineIndex,1} 
        daugthers      ::Array{Cascade.LineIndex,1} 
    end 



    """
    `Base.show(io::IO, level::Cascade.Level)`  ... prepares a proper printout of the variable level::Cascade.Level.
    """
    function Base.show(io::IO, level::Cascade.Level) 
        println(io, "energy:        $(level.energy)  ")
        println(io, "J:             $(level.J)  ")
        println(io, "parity:        $(level.parity)  ")
        println(io, "NoElectrons:   $(level.NoElectrons)  ")
        println(io, "relativeOcc:   $(level.relativeOcc)  ")
        println(io, "parents:       $(level.parents)  ")
        println(io, "daugthers:     $(level.daugthers)  ")
    end


    """
    `JAC.Cascade.computeTransitionLines(comp::Cascade.Computation)` ... computes in turn all the requested transition amplitudes and 
         Radiative.Line's, Auger.Line's, etc. as specified by the (list of) steps of the given cascade computationa. When compared with the 
         standard atomic process computations, the amount of output is largely reduced. A data::Cascade.Data is returned
    """
    function computeTransitionLines(comp::Cascade.Computation)
        linesA = Auger.Line[];    linesR = Radiative.Line[];    linesP = PhotoIonization.Line[]    
        augerSettings     = Auger.Settings(false, false, Tuple{Int64,Int64}[], 0., 1.0e6, 4, false)
        radiativeSettings = Radiative.Settings([E1], [JAC.UseBabushkin], false, false, false, false, Tuple{Int64,Int64}[], 0., 0., 1.0e6)
        println(" ")
        println("  Perform transition amplitude and line computations for $(length(comp.steps)) individual steps of cascade:")
        println("  Adapt the present augerSettings, RadiativeSettings, etc. for real computations.")
        print(  "  $augerSettings ")
        print(  " $radiativeSettings ")
        println(" ");    nt = 0
        for  st = 1:length(comp.steps)
            nc = length(comp.steps[st].initialMultiplet.levels) * length(comp.steps[st].finalMultiplet.levels) 
            println("  $st) Perform $(string(comp.steps[st].process)) amplitude computations for up to $nc lines (without selection rules):")
            println(" ")
            if      JAC.AugerX     == comp.steps[st].process  
                newLines = JAC.Auger.computeLines(comp.steps[st].finalMultiplet, comp.steps[st].initialMultiplet, comp.grid, augerSettings) 
                append!(linesA, newLines);    nt = length(linesA)
            elseif  JAC.RadiativeX == comp.steps[st].process   
                newLines = JAC.Radiative.computeLines(comp.steps[st].finalMultiplet, comp.steps[st].initialMultiplet, comp.grid, radiativeSettings) 
                append!(linesR, newLines);    nt = length(linesR)
            else   error("Unsupported atomic process in cascade computations.")
            end
            println("\n  Step $st:: A total of $(length(newLines)) $(string(comp.steps[st].process)) lines are calculated, giving now rise " *
                    "to a total of $nt $(string(comp.steps[st].process)) lines." )
        end
        #
        data = Cascade.Data(comp.name, linesR, linesA, linesP)
    end

    
    """
    `JAC.Cascade.determineBlocks(comp::Cascade.Computation, confs::Array{Configuration,1})`  ... determines all block::Cascade.Block that need 
         to be computed for this cascade. The different cascade approches follow different strategies in defining these blocks. 
         A blockList::Array{Cascade.Block,1} is returned.
    """
    function determineBlocks(comp::Cascade.Computation, confs::Array{Configuration,1})
        blockList = Cascade.Block[]
        #
        # In the averageSCA approach, use every configuration as an individual block
        if    comp.approach == averageSCA
            for  confa  in confs
                push!( blockList, Cascade.Block(confa.NoElectrons, [confa], false, JAC.Multiplet()) )
            end
        else  stop("Unsupported cascade approach.")
        end
        #
        # Calculate the multiplets for all blocks
        println(" ")
        println("  Cascade.determineBlocks-WARNING: " *
                "A total of $(length(blockList)) blocks have been determined ... but are now restricted to 5 blocks:\n")
        newBlockList  = Cascade.Block[]
        for i = 3:7  # 1:length(blockList) 
            sa = "";   na = 0;    for conf in blockList[i].confs   sa = sa * string(conf) * ", ";   na = na + conf.NoElectrons    end
            print("  Multiplet computations for $(sa[1:end-2]) with $na electrons ... ")
            basis     = perform("computation: SCF", blockList[i].confs, comp.nuclearModel, comp.grid, comp.asfSettings; printout=false)
            multiplet = perform("computation: CI", basis, comp.nuclearModel, comp.grid, comp.multipletSettings; printout=false)
            push!( newBlockList, Cascade.Block(blockList[i].NoElectrons, blockList[i].confs, true, multiplet) )
            println(" and $(length(multiplet.levels[1].basis.csfs)) CSF done. ")
        end
        #
        blockList = newBlockList
        #
        # Display all blocks
        println(" ")
        println("  Predefined configuration 'blocks' in the given cascade model:")
        println(" ")
        println("  ", JAC.TableStrings.hLine(134))
        println("      No.   Configurations                                                                       " *
                "      Range of total energies " * JAC.TableStrings.inUnits("energy") ) 
        println("  ", JAC.TableStrings.hLine(134))
        for  i = 1:length(blockList)
            sa = "   " * JAC.TableStrings.flushright( 6, string(i); na=2)
            sb = " ";  for conf in blockList[i].confs   sb = sb * string(conf) * ", "    end
            en = Float64[];   for j = 1:length(blockList[i].multiplet.levels)    push!(en, blockList[i].multiplet.levels[j].energy)    end
            minEn = minimum(en);   minEn = JAC.convert("energy: from atomic", minEn)
            maxEn = maximum(en);   maxEn = JAC.convert("energy: from atomic", maxEn)
            sa = sa * JAC.TableStrings.flushleft(90, sb[1:end-2]; na=2) 
            sa = sa * JAC.TableStrings.flushleft(30, string( round(minEn)) * " ... " * string( round(maxEn)); na=2)
            println(sa)
        end
        println("  ", JAC.TableStrings.hLine(134))
        #
        # If needeed, support their modification, for instance, by combining two or more blocks
        println(" ")
        println("  Modify individual blocks by given rules ? [currently No]")
        yes = false   # JAC.yesno("Modify individual blocks by given rules ?  [N|y]", "N")
        if  yes
            println("  The following rules can be applied to merge 'blocks'; give one instruction after the other -- not yet implemented:")
            println("    Rule:        ... to merge two or more blocks into a single one.")
            # printout again all new constructed blocks
        end

        return( blockList )
    end


    """
    `JAC.Cascade.determineSteps(comp::Cascade.Computation, blockList::Array{Cascade.Block,1})`  ... determines all steps::Cascade.Step that need 
         to be computed for this cascade. It cycles through the given processes and distinguished between the different cascade approaches. 
         It also checks that the averaged energies of the configuration allows such a step energetically. A stepList::Array{Cascade.Step,1} is 
         returned
    """
    function determineSteps(comp::Cascade.Computation, blockList::Array{Cascade.Block,1})
        stepList = Cascade.Step[]
        if    comp.approach == averageSCA
            for  a = 1:length(blockList)
                for  b = 1:length(blockList)
                    minEn = 100000.;   maxEn = -100000.
                    for  p = 1:length(blockList[a].multiplet.levels),  q = 1:length(blockList[b].multiplet.levels)
                        minEn = min(minEn, blockList[a].multiplet.levels[p].energy - blockList[b].multiplet.levels[q].energy)
                        maxEn = max(maxEn, blockList[a].multiplet.levels[p].energy - blockList[b].multiplet.levels[q].energy)
                    end
                    for  process  in  comp.processes
                        if      process == JAC.RadiativeX   
                            if  a == b   ||   minEn < 0.    continue   end
                            if  blockList[a].NoElectrons == blockList[b].NoElectrons
                                push!( stepList, Cascade.Step(process, blockList[a].confs, blockList[b].confs, 
                                                              true, blockList[a].multiplet, blockList[b].multiplet) )
                            end
                        elseif  process == JAC.AugerX       
                            if  a == b   ||   minEn < 0.    continue   end
                            if  blockList[a].NoElectrons == blockList[b].NoElectrons + 1
                                push!( stepList, Cascade.Step(process, blockList[a].confs, blockList[b].confs, 
                                                              true, blockList[a].multiplet, blockList[b].multiplet) )
                            end
                        else    error("stop a")
                        end
                    end
                end
            end
        #
        else  stop("Unsupported cascade approach.")
        end
        return( stepList )
    end
   

    """
    `JAC.Cascade.displayInitialLevels(multiplet::Multiplet, initialLevels::Array{Tuple{Int64,Float64},1})`  ... display the calculated initial 
         levels to screen together with their given relative occupation
    """
    function displayInitialLevels(multiplet::Multiplet, initialLevels::Array{Tuple{Int64,Float64},1})
        println(" ")
        println("  Initial levels, relative to the lowest, and their given occupation:")
        println(" ")
        println("  ", JAC.TableStrings.hLine(64))
        println("    Level  J Parity          Energy " * JAC.TableStrings.inUnits("energy") * "         rel. occupation ") 
        println("  ", JAC.TableStrings.hLine(64))
        for  i = 1:length(multiplet.levels)
            lev = multiplet.levels[i]
            en  = lev.energy - multiplet.levels[1].energy;    en_requested = JAC.convert("energy: from atomic", en)
            wx = 0.
            for  ilevel in initialLevels
                if  i in ilevel   wx = ilevel[2];    break    end
            end
            sb  = "          "   * string(wx)
            sc  = "   "  * JAC.TableStrings.level(i) * "     " * string(LevelSymmetry(lev.J, lev.parity)) * "     "
            @printf("%s %.15e %s %s", sc, en_requested, sb, "\n")
        end
        println("  ", JAC.TableStrings.hLine(64))
        return( nothing )
    end
   

    """
    `JAC.Cascade.displaySteps(steps::Array{Cascade.Step,1})` ... displays all predefined steps in a neat table and supports to delete
         individual steps from the list.
    """
    function displaySteps(steps::Array{Cascade.Step,1})
        println(" ")
        println("  Steps that are defined for the current cascade due to the given approach:")
        println(" ")
        println("  ", JAC.TableStrings.hLine(170))
        sa = "  "
        sa = sa * JAC.TableStrings.center( 9, "Step-No"; na=2)
        sa = sa * JAC.TableStrings.flushleft(11, "Process"; na=1)
        sa = sa * JAC.TableStrings.flushleft(55, "Initial:  No CSF, configuration(s)"; na=4)
        sa = sa * JAC.TableStrings.flushleft(55, "Final:  No CSF, configuration(s)"; na=4)
        sa = sa * JAC.TableStrings.flushleft(40, "Energies from ... to in " * JAC.TableStrings.inUnits("energy"); na=4)
        println(sa)
        println("  ", JAC.TableStrings.hLine(170))
        #
        for  i = 1:length(steps)
            sa = " " * JAC.TableStrings.flushright( 7, string(i); na=5)
            sa = sa  * JAC.TableStrings.flushleft( 11, string(steps[i].process); na=1)
            sb = "";   for conf in steps[i].initialConfs   sb = sb * string(conf) * ", "    end
            sa = sa  * JAC.TableStrings.flushright( 5, string( length(steps[i].initialMultiplet.levels[1].basis.csfs) )*", "; na=0) 
            sa = sa  * JAC.TableStrings.flushleft( 50, sb[1:end-2]; na=4)
            sb = "";   for conf in steps[i].finalConfs   sb = sb * string(conf) * ", "    end
            sa = sa  * JAC.TableStrings.flushright( 5, string( length(steps[i].finalMultiplet.levels[1].basis.csfs) )*", "; na=0) 
            sa = sa  * JAC.TableStrings.flushleft( 50, sb[1:end-2]; na=4)
            minEn = 1000.;   maxEn = -1000.;
            for  p = 1:length(steps[i].initialMultiplet.levels),  q = 1:length(steps[i].finalMultiplet.levels)
                minEn = min(minEn, steps[i].initialMultiplet.levels[p].energy - steps[i].finalMultiplet.levels[q].energy)
                maxEn = max(maxEn, steps[i].initialMultiplet.levels[p].energy - steps[i].finalMultiplet.levels[q].energy)
            end
            minEn = JAC.convert("energy: from atomic", minEn);   maxEn = JAC.convert("energy: from atomic", maxEn)
            sa = sa * string( round(minEn)) * " ... " * string( round(maxEn))
            println(sa)
        end
        println("  ", JAC.TableStrings.hLine(170))
    end


    """
    `JAC.Cascade.generateConfigurationList(initialConfs::Array{Configuration,1}, further::Int64, NoShake::Int64)`  ... generates all possible 
         (decay) configurations with up to further holes and with NoShake displacements. First, all configuratons are generated for which the 
         hole is either moved 'outwards' or is moved and a second 'outer' hole is created; this step is repated further + 2 times. From this 
         generated list, only those configurations are kept with up to further holes, when compared with the initial configuration. 
         A confList::Array{Configuration,1} is returned.
    """
    function generateConfigurationList(initialConfs::Array{Configuration,1}, further::Int64, NoShake::Int64)
        confList = copy(initialConfs);    cList = copy(initialConfs);   initialNoElectrons = initialConfs[1].NoElectrons
        # First, move and generate new 'outer' hole without displacements
        for  fur = 1:further+1
            newConfList = Configuration[]
            for conf  in cList
                holeList = JAC.determineHoleShells(conf)
                for  holeShell in holeList
                    wa = generateConfigurationsWith1OuterHole(conf,  holeShell);   append!(newConfList, wa)
                    wa = generateConfigurationsWith2OuterHoles(conf, holeShell);   append!(newConfList, wa)
                end
            end
            if  length(newConfList) > 0    newConfList = JAC.excludeDoubles(newConfList)    end
            cList = newConfList
            append!(confList, newConfList)
        end
        # Make sure that only configurations with up to further holes are returned
        newConfList = Configuration[]
        for   conf in confList   
            if  conf.NoElectrons + further >= initialNoElectrons   push!(newConfList, conf)    end
        end
        # Add further shake-displacements if appropriate
        newConfList = JAC.excludeDoubles(newConfList)
        return( newConfList )
    end


    """
    `JAC.Cascade.generateConfigurationsWith1OuterHole(conf,  holeShell)`  ... generates all possible (decay) configurations where the hole in 
         holeShell is moved 'outwards'. A confList::Array{Configuration,1} is returned.
    """
    function generateConfigurationsWith1OuterHole(conf::Configuration,  holeShell::Shell)
         shList = JAC.generate("shells: ordered list for NR configurations", [conf]);   i0 = 0
         for  i = 1:length(shList)
             if   holeShell == shList[i]    i0 = i;    break    end
         end
         if  i0 == 0   error("stop a")   end
         #
         # Now move the hole 'outwards'
         confList = Configuration[]
         for  i = i0+1:length(shList)
             if  haskey(conf.shells, shList[i])  &&  conf.shells[ shList[i] ] >= 1  
                 newshells = copy( conf.shells )
                 newshells[ shList[i] ] = newshells[ shList[i] ] - 1
                 newshells[ holeShell ] = newshells[ holeShell ] + 1
                 push!(confList, Configuration( newshells, conf.NoElectrons ) )
             end
         end
         return( confList )
    end


    """
    `JAC.Cascade.generateConfigurationsWith2OuterHoles(conf,  holeShell)`  ... generates all possible (decay) configurations where the hole 
         in holeShell is moved 'outwards'. A confList::Array{Configuration,1} is returned.
    """
    function generateConfigurationsWith2OuterHoles(conf::Configuration,  holeShell::Shell)
         shList = JAC.generate("shells: ordered list for NR configurations", [conf]);   i0 = 0
         for  i = 1:length(shList)
             if   holeShell == shList[i]    i0 = i;    break    end
         end
         if  i0 == 0   error("stop a")   end
         #
         # Now move the hole 'outwards'
         confList = Configuration[]
         for  i = i0+1:length(shList)
             if  haskey(conf.shells, shList[i])  &&  conf.shells[ shList[i] ] >= 2  
                 newshells = copy( conf.shells )
                 newshells[ shList[i] ] = newshells[ shList[i] ] - 2
                 newshells[ holeShell ] = newshells[ holeShell ] + 1
                 push!(confList, Configuration( newshells, conf.NoElectrons - 1 ) )
             end
             #
             for  j = i0+1:length(shList)
                 if  i != j   &&   haskey(conf.shells, shList[i])  &&  conf.shells[ shList[i] ] >= 1   &&
                                   haskey(conf.shells, shList[j])  &&  conf.shells[ shList[j] ] >= 1 
                     newshells = copy( conf.shells )
                     newshells[ shList[i] ] = newshells[ shList[i] ] - 1
                     newshells[ shList[j] ] = newshells[ shList[j] ] - 1
                     newshells[ holeShell ] = newshells[ holeShell ] + 1
                     push!(confList, Configuration( newshells, conf.NoElectrons - 1 ) )
                 end
             end
         end
         return( confList )
    end



    """
    `JAC.Cascade.groupConfigurationList(Z::Float64, confs::Array{Configuration,1})` ... group & display the configuration list into sublists 
         with the same No. of electrons; this lists are displayed together with an estimated total energy.
    """
    function groupConfigurationList(Z::Float64, confs::Array{Configuration,1})
        minNoElectrons = 1000;   maxNoElectrons = 0  
        for  conf in confs
            minNoElectrons = min(minNoElectrons, conf.NoElectrons)
            maxNoElectrons = max(maxNoElectrons, conf.NoElectrons)
        end
        #
        println(" ")
        println("  Configuration used in the cascade:")
        confList = Configuration[]
        for  n = maxNoElectrons:-1:minNoElectrons
            println("\n    Configuration(s) with $n electrons:")
            for  conf in confs
                if n == conf.NoElectrons   
                    push!(confList, conf ) 
                    wa = JAC.provide("binding energy", round(Int64, Z), conf);    wa = JAC.convert("energy: from atomic", wa)
                    sa = "   av. BE = "  * string( round(-wa) ) * "  " * JAC.TableStrings.inUnits("energy")
                    println("      " * string(conf) * sa )
                end  
            end
        end
        return( confList )
    end


    """
    `JAC.Cascade.modifySteps(comp::Cascade.Computation, steps::Array{Cascade.Step,1})` ... allows the user to modify the steps, for instance, 
         by deleting selected steps. A newComp::Cascade.Computation is returned which, in addition to the data of comp, now contains also all 
         steps of the cascade.
    """
    function modifySteps(comp::Cascade.Computation, steps::Array{Cascade.Step,1})
        #
        # if needeed, support their modificationof the predefined steps, for instance, by deleting one or more steps or ...
        println(" ")
        println("  Modify the predefined list of cascade steps by given rules ? [currently No]")
        yes = false   # JAC.yesno("  Modify the predefined list of cascade steps by given rules ?  [N|y]", "N")
        if  yes
            println("  The following rules can be applied to delete steps or ...; give one instruction after the other -- not yet implemented:")
            println("    Rule:        ... to delete one or several steps from the list.")
            # printout again the new constructed step list.
        end
        
        newComp = Cascade.Computation(comp.name, comp.nuclearModel, comp.grid, comp.asfSettings, comp.approach,
                                      comp.processes, comp.initialConfs, comp.initialLevels, comp.maxElectronLoss, comp.NoShakeDisplacements,
                                      comp.shakeFromShells, comp.shakeToShells, steps)
        return( newComp )
    end


    """
    `JAC.Cascade.simulateLevelDistribution(simulation::Cascade.Simulation, data::Cascade.Data)` ... sorts all levels as given by data
         and propagates their (occupation) probability until no further changes occur. For this propagation, it runs through all levels and 
         propagates the probabilty until no level probability changes anymore. The final level distribution is then used to derive the ion 
         distribution or the level distribution, if appropriate. Nothing is returned.
    """
    function simulateLevelDistribution(simulation::Cascade.Simulation, data::Cascade.Data)
        levels = JAC.Cascade.extractLevels(data)
        JAC.Cascade.displayLevelTree(data.name, levels, data)
        JAC.Cascade.propagateProbability!(levels, data)
        if   JAC.Cascade.IonDist   in simulation.properties    JAC.Cascade.displayIonDistribution(data.name, levels)     end
        if   JAC.Cascade.FinalDist in simulation.properties    JAC.Cascade.displayLevelDistribution(data.name, levels)   end

        return( nothing )
    end


    """
    `JAC.Cascade.displayIonDistribution(sc::String, levels::Array{Cascade.Level,1})` ... displays the (current or final) ion distribution 
         in a neat table. Nothing is returned.
    """
    function displayIonDistribution(sc::String, levels::Array{Cascade.Level,1})
        minElectrons = 1000;   maxElectrons = 0
        for  level in levels   minElectrons = min(minElectrons, level.NoElectrons);   maxElectrons = max(maxElectrons, level.NoElectrons)   end
        println(" ")
        println("  (Final) Ion distribution for the cascade:  $sc   mine = $minElectrons maxe = $maxElectrons ")
        println(" ")
        println("  ", JAC.TableStrings.hLine(31))
        sa = "  "
        sa = sa * JAC.TableStrings.center(14, "No. electrons"; na=4)        
        sa = sa * JAC.TableStrings.center(10,"Rel. occ.";      na=2)
        println(sa)
        println("  ", JAC.TableStrings.hLine(31))
        for n = maxElectrons:-1:minElectrons
            sa = "             " * string(n);   sa = sa[end-10:end];   prob = 0.
            for  level in levels    if  n == level.NoElectrons   prob = prob + level.relativeOcc    end    end
            sa = sa * "         " * @sprintf("%.5e", prob)
            println(sa)
        end
        println("  ", JAC.TableStrings.hLine(31))

        return( nothing )
    end


    """
    `JAC.Cascade.displayLevelDistribution(sc::String, levels::Array{Cascade.Level,1})` ... displays the (current or final) level distribution 
         in a neat table. Only those levels with a non-zero occupation are displayed here. Nothing is returned.
    """
    function displayLevelDistribution(sc::String, levels::Array{Cascade.Level,1})
        minElectrons = 1000;   maxElectrons = 0;   energies = zeros(length(levels))
        for  i = 1:length(levels)
            minElectrons = min(minElectrons, levels[i].NoElectrons);   maxElectrons = max(maxElectrons, levels[i].NoElectrons)
            energies[i]  = levels[i].energy   
        end
        enIndices = sortperm(energies, rev=true)
        # Now printout the results
        println(" ")
        println("  (Final) Level distribution for the cascade:  $sc")
        println(" ")
        println("  ", JAC.TableStrings.hLine(57))
        sa = "  "
        sa = sa * JAC.TableStrings.center(14, "No. electrons"; na=2)        
        sa = sa * JAC.TableStrings.center( 6, "J^P"          ; na=2);               
        sa = sa * JAC.TableStrings.center(16, "Energy " * JAC.TableStrings.inUnits("energy"); na=4)
        sa = sa * JAC.TableStrings.center(10, "Rel. occ.";                                    na=2)
        println(sa)
        println("  ", JAC.TableStrings.hLine(57))
        for n = maxElectrons:-1:minElectrons
            sa = "            " * string(n);   sa = sa[end-10:end]
            for  en in enIndices
                if  n == levels[en].NoElectrons  ##    &&  levels[en].relativeOcc > 0
                    sb = sa * "       " * string( LevelSymmetry(levels[en].J, levels[en].parity) )     * "    "
                    sb = sb * @sprintf("%.6e", JAC.convert("energy: from atomic", levels[en].energy))  * "      "
                    sb = sb * @sprintf("%.5e", levels[en].relativeOcc) 
                    sa = "           "
                    println(sb)
                end
            end
        end
        println("  ", JAC.TableStrings.hLine(57))

        return( nothing )
    end


    """
    `JAC.Cascade.displayLevelTree(sc::String, levels::Array{Cascade.Level,1}, data::Cascade.Data)` ... displays all defined levels  in a neat 
         table, together with their No. of electrons, symmetry, level energy, current (relative) population as well as analogue information about 
         their parents and daugther levels. This enables one to recognize (and perhaps later add) missing parent and daughter levels. 
         Nothing is returned.
    """
    function displayLevelTree(sc::String, levels::Array{Cascade.Level,1}, data::Cascade.Data)
        minElectrons = 1000;   maxElectrons = 0;   energies = zeros(length(levels))
        for  i = 1:length(levels)
            minElectrons = min(minElectrons, levels[i].NoElectrons);   maxElectrons = max(maxElectrons, levels[i].NoElectrons)
            energies[i]  = levels[i].energy   
        end
        enIndices = sortperm(energies, rev=true)
        # Now printout the results
        println(" ")
        println("  Level tree of this cascade:  $sc")
        println(" ")
        println("  ", JAC.TableStrings.hLine(175))
        sa = "  "
        sa = sa * JAC.TableStrings.center( 6, "No. e-"; na=2)        
        sa = sa * JAC.TableStrings.center( 6, "J^P"          ; na=2);               
        sa = sa * JAC.TableStrings.center(16, "Energy " * JAC.TableStrings.inUnits("energy"); na=4)
        sa = sa * JAC.TableStrings.center(10, "Rel. occ.";                                    na=5)
        sb = "Parents P(A: No_e, sym, energy) and Daughters D(R: No_e, sym, energy);  all energies in " * JAC.TableStrings.inUnits("energy")
        sa = sa * JAC.TableStrings.flushleft(100, sb; na=2)
        println(sa)
        println("  ", JAC.TableStrings.hLine(175))
        for n = maxElectrons:-1:minElectrons
            sa = "            " * string(n);   sa = sa[end-5:end]
            for  en in enIndices
                if  n == levels[en].NoElectrons
                    sb = sa * "      " * string( LevelSymmetry(levels[en].J, levels[en].parity) )      * "   "
                    sb = sb * @sprintf("%.6e", JAC.convert("energy: from atomic", levels[en].energy))  * "      "
                    sb = sb * @sprintf("%.5e", levels[en].relativeOcc)                                 * "    "
                    pProcessSymmetryEnergyList = Tuple{JAC.AtomicProcess,Int64,LevelSymmetry,Float64}[]
                    dProcessSymmetryEnergyList = Tuple{JAC.AtomicProcess,Int64,LevelSymmetry,Float64}[]
                    for  p in levels[en].parents
                        idx = p.index
                        if      p.process == JAC.AugerX        lev = data.linesA[idx].initialLevel
                        elseif  p.process == JAC.RadiativeX    lev = data.linesR[idx].initialLevel
                        elseif  p.process == JAC.Photo         lev = data.linesP[idx].initialLevel
                        else    error("stop a")    end
                        push!( pProcessSymmetryEnergyList, (p.process, lev.basis.NoElectrons, LevelSymmetry(lev.J, lev.parity), lev.energy) )
                    end
                    for  d in levels[en].daugthers
                        idx = d.index
                        if      d.process == JAC.AugerX        lev = data.linesA[idx].finalLevel
                        elseif  d.process == JAC.RadiativeX    lev = data.linesR[idx].finalLevel
                        elseif  d.process == JAC.Photo         lev = data.linesP[idx].finalLevel
                        else    error("stop b")    end
                        push!( dProcessSymmetryEnergyList, (d.process, lev.basis.NoElectrons, LevelSymmetry(lev.J, lev.parity), lev.energy) )
                    end
                    wa = JAC.TableStrings.processSymmetryEnergyTupels(120, pProcessSymmetryEnergyList, "P")
                    if  length(wa) > 0    sc = sb * wa[1];    println( sc )    else    println( sb )   end  
                    for  i = 2:length(wa)
                        sc = JAC.TableStrings.hBlank( length(sb) ) * wa[i];    println( sc )
                    end
                    wa = JAC.TableStrings.processSymmetryEnergyTupels(120, dProcessSymmetryEnergyList, "D")
                    for  i = 1:length(wa)
                        sc = JAC.TableStrings.hBlank( length(sb) ) * wa[i];    println( sc )
                    end
                    sa = "      "
                end
            end
        end
        println("  ", JAC.TableStrings.hLine(175))

        return( nothing )
    end


    """
    `JAC.Cascade.propagateProbability!(levels::Array{Cascade.Level,1}, data::Cascade.Data)` ... propagates the relative level occupation through 
         the levels of the cascade until no further change occur in the relative level occupation. The argument levels is modified during the 
         propagation, but nothing is returned otherwise.
    """
    function propagateProbability!(levels::Array{Cascade.Level,1}, data::Cascade.Data)
        n = 0
        println("\n  Probability propagation through $(length(levels)) levels of the cascade:")
        while true
            n = n + 1;    totalProbability = 0.
            print("    $n-th round ... ")
            for  level in levels
                if   level.relativeOcc > 0.   && length(level.daugthers) > 0
                    # A level with relative occupation > 0 has still 'daugther' levels; collect all decay rates for this level
                    prob  = level.relativeOcc;   totalProbability = totalProbability + prob;   rates = zeros(length(level.daugthers))
                    level.relativeOcc = 0.
                    for  i = 1:length(level.daugthers)
                        idx = level.daugthers[i].index
                        if      level.daugthers[i].process == JAC.RadiativeX    rate[i] = data.lineR[idx].photonRate.Babushkin
                        elseif  level.daugthers[i].process == JAC.AugerX        rate[i] = data.lineA[idx].totalRate
                        else    error("stop a; process = $(level.daugthers[i].process) ")
                        end
                    end
                    totalRate = sum(rates)
                    # Shift the relative occupation to the 'daugther' levels due to the different decay pathes
                    for  i = 1:length(level.daugthers)
                        idx = level.daugthers[i].index
                        if      level.daugthers[i].process == JAC.RadiativeX    line = data.lineR[idx]
                        elseif  level.daugthers[i].process == JAC.AugerX        line = data.lineA[idx]
                        else    error("stop b; process = $(level.daugthers[i].process) ")
                        end
                        level = Cascade.Level( line.finalLevel.energy, line.finalLevel.J, line.finalLevel.parity, 
                                               line.finalLevel.basis.NoElectrons, 0., Cascade.LineIndex[], Cascade.LineIndex[] )
                        kk    = Cascade.findLevelIndex(level, levels)
                        levels[kk].relativeOcc = levels[kk].relativeOcc + prob * rates[i] / totalRate
                    end
                end
            end
            println("has propagated a total of $totalProbability level occupation.")
            # Cycle once more if the relative occupation has still changed
            if  totalProbability == 0.    break    end
        end

        return( nothing )
    end


    """
    `JAC.Cascade.findLevelIndex(level::Cascade.Level, levels::Array{Cascade.Level,1})` ... find the index of the given level within the given
         list of levels; an idx::Int64 is returned and an error message is issued if the level is not found in the list.
    """
    function findLevelIndex(level::Cascade.Level, levels::Array{Cascade.Level,1})
        for  k = 1:length(levels)
            if  level.energy == levels[k].energy  &&   level.J == levels[k].J   &&   level.parity == levels[k].parity   &&
                level.NoElectrons == levels[k].NoElectrons
                kk = k;   return( kk )
            end
        end
        error("findLevelIndex():  No index was found;\n   level = $(level) ")
    end


    """
    `JAC.Cascade.extractLevels(data::Cascade.Data)` ... extracts and sorts all levels from the given cascade data into a new 
         levelList::Array{Cascade.Level,1} to simplify the propagation of the probabilities. In this list, every level of the overall cascade 
         just occurs just once, together with its parent lines (which may populate the level) and the daugther lines (to which the pobability 
         may decay). A levelList::Array{Cascade.Level,1} is returned.
    """
    function extractLevels(data::Cascade.Data)
        levels = Cascade.Level[]
        print("\n  Extract, sort and unify the list of levels of the cascade ... ")
        for  i = 1:length(data.linesR)
            line = data.linesR[i]
            iLevel = Cascade.Level( line.initialLevel.energy, line.initialLevel.J, line.initialLevel.parity, line.initialLevel.basis.NoElectrons,
                                    line.initialLevel.relativeOcc, Cascade.LineIndex[], [ Cascade.LineIndex(JAC.RadiativeX, i)] ) 
            Cascade.pushLevels!(levels, iLevel)  
            fLevel = Cascade.Level( line.finalLevel.energy, line.finalLevel.J, line.finalLevel.parity, line.finalLevel.basis.NoElectrons,
                                    line.finalLevel.relativeOcc, [ Cascade.LineIndex(JAC.RadiativeX, i)], Cascade.LineIndex[] ) 
            Cascade.pushLevels!(levels, fLevel)  
        end

        for  i = 1:length(data.linesA)
            line = data.linesA[i]
            iLevel = Cascade.Level( line.initialLevel.energy, line.initialLevel.J, line.initialLevel.parity, line.initialLevel.basis.NoElectrons,
                                    line.initialLevel.relativeOcc, Cascade.LineIndex[], [ Cascade.LineIndex(JAC.AugerX, i)] ) 
            Cascade.pushLevels!(levels, iLevel)  
            fLevel = Cascade.Level( line.finalLevel.energy, line.finalLevel.J, line.finalLevel.parity, line.finalLevel.basis.NoElectrons,
                                    line.finalLevel.relativeOcc, [ Cascade.LineIndex(JAC.AugerX, i)], Cascade.LineIndex[] ) 
            Cascade.pushLevels!(levels, fLevel)  
        end

        for  i = 1:length(data.linesP)
            line = data.linesP[i]
            iLevel = Cascade.Level( line.initialLevel.energy, line.initialLevel.J, line.initialLevel.parity, line.initialLevel.basis.NoElectrons,
                                    line.initialLevel.relativeOcc, Cascade.LineIndex[], [ Cascade.LineIndex(JAC.Photo, i)] ) 
            Cascade.pushLevels!(levels, iLevel)  
            fLevel = Cascade.Level( line.finalLevel.energy, line.finalLevel.J, line.finalLevel.parity, line.finalLevel.basis.NoElectrons,
                                    line.finalLevel.relativeOcc, [ Cascade.LineIndex(JAC.Photo, i)], Cascade.LineIndex[] ) 
            Cascade.pushLevels!(levels, fLevel)  
        end

        println("a total of $(length(levels)) levels were found.")
        return( levels )
    end


    """
    `JAC.Cascade.pushLevels!(levels::Array{Cascade.Level,1}, newLevel::Cascade.Level)` ... push's the information of newLevel of levels.
         This is the standard 'push!(levels, newLevel)' if newLevel is not yet including in levels, and the proper modification of the parent 
         and daugther lines of this level otherwise. The argument levels::Array{Cascade.Level,1} is modified and nothing is returned otherwise.
    """
    function pushLevels!(levels::Array{Cascade.Level,1}, newLevel::Cascade.Level)
        for  i = 1:length(levels)
            if  newLevel.energy == levels[i].energy  &&  newLevel.J == levels[i].J  &&  newLevel.parity == levels[i].parity
                append!(levels[i].parents,   newLevel.parents)
                append!(levels[i].daugthers, newLevel.daugthers)
                return( nothing )
            end
        end
        push!( levels, newLevel)
        ##x info("... one level added, n = $(length(levels)) ")
        return( nothing )
    end

end # module

