//==- RISCVInstrFormats.td - RISCV Instruction Formats --*- tablegen -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Basic RISCV instruction definition
//===----------------------------------------------------------------------===//

class InstRISCV<int size, dag outs, dag ins, string asmstr,
                  list<dag> pattern> : Instruction {
  let Namespace = "RISCV";

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let Size = size;
  let Pattern = pattern;
  let AsmString = asmstr;

  let AddedComplexity = 1;

  // Used to identify a group of related instructions, such as ST and STY.
  string Function = "";

  // "12" for an instruction that has a ...Y equivalent, "20" for that
  // ...Y equivalent.
  string PairType = "none";

  // True if this instruction is a simple load of a register
  // (with no sign or zero extension).
  bit SimpleLoad = 0;

  // True if this instruction is a simple store of a register
  // (with no truncation).
  bit SimpleStore = 0;

  let TSFlags{0} = SimpleLoad;
  let TSFlags{1} = SimpleStore;
}

class PsuedoInst<dag outs, dag ins, list<dag> pattern>
  : InstRISCV<4, outs, ins,"PSEUDO", pattern> {
  let isPseudo = 1;
  let isCodeGenOnly = 1;
}

/***************
*RISCV Instruction Formats
*/

//R-Type
class InstR<string mnemonic, bits<7> op, bits<10> funct10, 
            SDPatternOperator operator, RegisterOperand cls1, 
            RegisterOperand cls2>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src2, cls2:$src1), 
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator cls2:$src1, cls2:$src2))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;

  let Inst{31-27} = RD;
  let Inst{26-22} = RS1;
  let Inst{21-17} = RS2;
  let Inst{16- 7} = funct10;
  let Inst{6 - 0} = op;
}

//R-Type
class InstR64<string mnemonic, bits<7> op, bits<10> funct10, 
            SDPatternOperator operator, RegisterOperand cls1, 
            RegisterOperand cls2>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src2, cls2:$src1), 
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (sext (operator cls2:$src1, cls2:$src2)))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;

  let Inst{31-27} = RD;
  let Inst{26-22} = RS1;
  let Inst{21-17} = RS2;
  let Inst{16- 7} = funct10;
  let Inst{6 - 0} = op;
}

// PACO ALU instr format 32 bit operands
class InstPALU32<string mnemonic, bits<7> op, bits<4> funct4,  
            SDPatternOperator operator, RegisterOperand cls1, 
            RegisterOperand cls2, Immediate imm>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src2, cls2:$src1, imm:$src3), 
                mnemonic#"\t$dst, $src1, $src2, $src3", 
                [(set cls1:$dst, (operator cls2:$src1, cls2:$src2, imm:$src3))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  //bits<6> IMM;

  let Inst{31-26} = 0;
  let Inst{25}    = funct4{3};
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct4{2-0};
  let Inst{11-7}  = RD;
  let Inst{6 - 0} = op;
}

// PACO ALU instr format 64 bit operands
class InstPALU64<string mnemonic, bits<7> op, bits<4> funct4,  
            SDPatternOperator operator, RegisterOperand cls1, 
            RegisterOperand cls2, Immediate imm>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src2, cls2:$src1, imm:$src3), 
                mnemonic#"\t$dst, $src1, $src2, $src3", 
                [(set cls1:$dst, (operator cls2:$src1, cls2:$src2, imm:$src3))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  //bits<6> IMM;

  let Inst{31-26} = 0;
  let Inst{25}    = funct4{3};
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct4{2-0};
  let Inst{11-7}  = RD;
  let Inst{6 - 0} = op;
}


// PACO LUTL instr format
class InstPLUTL<string mnemonic, bits<7> op,  
            SDPatternOperator operator, RegisterOperand cls1, Immediate imm,
            Immediate cor>
  : InstRISCV<4, (outs), 
    (ins cls1:$src1, cor:$src2, imm:$src34, imm:$src33, imm:$src32, imm:$src31), 
                mnemonic#"\t$src1, $src31, 0, $src2", 
                [(operator cls1:$src1, cor:$src2, imm:$src34, imm:$src33, imm:$src32, imm:$src31)]> {
  field bits<32> Inst;

  bits<5> RS1;
  bits<1> RST;
  bits<31> LS4;
  bits<31> LS3;
  bits<31> LS2;
  bits<31> LS;

  let Inst{31-30} = 0;
  let Inst{29-27} = 0;
  let Inst{26-25} = LS{4-3};
  let Inst{24-20} = 0;
  let Inst{19-15} = RS1;
  let Inst{14-12} = LS{2-0};
  let Inst{11-8 } = 0;
  let Inst{7}     = RST{0};
  let Inst{6-0}   = op;
  
}

// PACO LUTS instr format
class InstPLUTS<string mnemonic, bits<7> op,  
            SDPatternOperator operator, 
            RegisterOperand cls1, Immediate imm>
  : InstRISCV<4, (outs cls1:$dst), (ins imm:$src14, imm:$src13, imm:$src12, imm:$src11), 
                mnemonic#"\t$dst, $src11", 
                [(set cls1:$dst, (operator imm:$src14, imm:$src13, imm:$src12, imm:$src11))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<31> LS4;
  bits<31> LS3;
  bits<31> LS2;
  bits<31> LS;

  let Inst{31-30} = 2;
  let Inst{29-27} = 0;
  let Inst{26-25} = LS{4-3};
  let Inst{24-15} = 0;
  let Inst{14-12} = LS{2-0};
  let Inst{11-7 } = RD;
  let Inst{6-0}   = op;
  
}

// PACO LUTE instr format
class InstPLUTE<string mnemonic, bits<7> op,  
            SDPatternOperator operator, 
            RegisterOperand cls1, RegisterOperand cls2, Immediate imm1, Immediate imm2>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src1, imm1:$src24, imm1:$src23, imm1:$src22, imm1:$src21, imm2:$src3), 
                mnemonic#"\t$dst, $src1, $src21, $src3", 
                [(set cls1:$dst, (operator cls2:$src1, imm1:$src24, imm1:$src23, imm1:$src22, imm1:$src21, imm2:$src3))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<31> LS4;
  bits<31> LS3;
  bits<31> LS2;
  bits<31> LS;

  let Inst{31-30} = 1;
  let Inst{29-27} = 0;
  let Inst{26-25} = LS{4-3};
  let Inst{24-20} = 0;
  let Inst{19-15} = RS1;
  let Inst{14-12} = LS{2-0};
  let Inst{11-7 } = RD;
  let Inst{6-0}   = op;
  
}

// PACO LUTE3 instr format
class InstPLUTE3<string mnemonic, bits<7> op,  
            SDPatternOperator operator, 
            RegisterOperand cls1, RegisterOperand cls2, RegisterOperand cls3, RegisterOperand cls4, Immediate imm>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src1, cls3:$src2, cls4:$src3, imm:$src44, imm:$src43, imm:$src42, imm:$src41), 
                mnemonic#"\t$dst, $src1, $src2, $src3, $src41", 
                [(set cls1:$dst, (operator cls2:$src1, cls3:$src2, cls4:$src3, imm:$src44, imm:$src43, imm:$src42, imm:$src41))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  bits<5> RS3;
  bits<31> LS4;
  bits<31> LS3;
  bits<31> LS2;
  bits<31> LS;
  
  let Inst{31-27} = RS3;
  let Inst{26-25} = LS{4-3};
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = LS{2-0};
  let Inst{11-7 } = RD;
  let Inst{6-0}   = op;
  
}

//LR/SC
class InstLR<string mnemonic, bits<3> funct3,
             RegisterOperand cls1, Operand cls2>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src2), 
                mnemonic#"\t$dst, $src2", 
                []> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;

  let Inst{31-27} = 0b00010;
  let Inst{26} = 0;//aq
  let Inst{25} = 0;//rl
  let Inst{24-20} = 0b0000;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = 0b0101111;
}

class InstSC<string mnemonic, bits<3> funct3,
             RegisterOperand reg, Operand memOp>
  : InstRISCV<4, (outs reg:$dst), (ins reg:$src2, memOp:$src1), 
                mnemonic#"\t$dst, $src2, $src1", 
                []> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;

  let Inst{31-27} = 0b00011;
  let Inst{26} = 0;//aq
  let Inst{25} = 0;//rl
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = 0b0101111;
}

//A-Type
class InstA<string mnemonic, bits<7> op, bits<5> funct5, bits<3> funct3,
            SDPatternOperator operator, RegisterOperand cls1, 
            Operand cls2>
  : InstRISCV<4, (outs cls1:$dst), (ins cls1:$src1, cls2:$src2), 
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator regaddr:$src2, cls1:$src1))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;

  let Inst{31-27} = funct5;
  let Inst{26} = 0;//aq
  let Inst{25} = 0;//rl
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}

//R4-Type
class InstR4<string mnemonic, bits<7> op, bits<5> funct5,
            SDPatternOperator operator1, SDPatternOperator operator2,
            RegisterOperand cls1, RegisterOperand cls2>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src3, cls2:$src2, cls2:$src1), 
                mnemonic#"\t$dst, $src1, $src2, $src3", 
                [(set cls1:$dst, (operator2 (operator1 cls2:$src1, cls2:$src2), cls2:$src3))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  bits<5> RS3;

  let Inst{31-27} = RD;
  let Inst{26-22} = RS1;
  let Inst{21-17} = RS2;
  let Inst{16-12} = RS3;
  let Inst{11- 7} = funct5;
  let Inst{6 - 0} = op;
}
//Load-Type
class InstLoad<string mnemonic, bits<7> op, bits<3> funct3,
            SDPatternOperator opNode,
            RegisterOperand cls1,
            Operand memOp>
  : InstRISCV<4, (outs cls1:$dst), (ins memOp:$addr), 
                mnemonic#"\t$dst, $addr", 
                [(set cls1:$dst, (opNode addr:$addr))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<12> IMM;

  let Inst{31-27} = RD;
  let Inst{26-22} = RS1;
  let Inst{21-17} = IMM{11-7};
  let Inst{16-10} = IMM{6 -0};
  let Inst{9 - 7} = funct3;
  let Inst{6 - 0} = op;
}

class InstStore<string mnemonic, bits<7> op, bits<3> funct3,
                SDPatternOperator opNode,
                RegisterOperand cls1,
                Operand memOp>
  : InstRISCV<4, (outs), (ins cls1:$src, memOp:$addr),
              mnemonic#"\t$src, $addr", 
              [(opNode cls1:$src, addr:$addr)]> {
  field bits<32> Inst;

  bits<5> RS2;
  bits<5> RS1;
  bits<12> IMM;

  let Inst{31-27} = IMM{11-7};
  let Inst{26-22} = RS1;
  let Inst{21-17} = RS2;
  let Inst{16-10} = IMM{6 -0};
  let Inst{9 - 7} = funct3;
  let Inst{6 - 0} = op;
}

//I-Type
class InstI<string mnemonic, bits<7> op, bits<3> funct3,
            SDPatternOperator operator, RegisterOperand cls1, RegisterOperand cls2,
            Immediate imm>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src1, imm:$src2), 
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator cls2:$src1, imm:$src2))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<12> IMM;

  let Inst{31-27} = RD;
  let Inst{26-22} = RS1;
  let Inst{21-17} = IMM{11-7};
  let Inst{16-10} = IMM{6 -0};
  let Inst{9 - 7} = funct3;
  let Inst{6 - 0} = op;
}

//B-Type, too different to consolidate further
class InstB<bits<7> op, bits<3> funct3, dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstRISCV<4, outs, ins, asmstr, pattern> {
  field bits<32> Inst;

  bits<5> RS1;
  bits<5> RS2;
  bits<12> IMM;

  let Inst{31-27} = IMM{11-7};
  let Inst{26-22} = RS1;
  let Inst{21-17} = RS2;
  let Inst{16-10} = IMM{6 -0};
  let Inst{9 - 7} = funct3;
  let Inst{6 - 0} = op;
}

//U-Type, only two instructions fit here so no further condensation
class InstU<bits<7> op, dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstRISCV<4, outs, ins, asmstr, pattern> {
  field bits<32> Inst;

  bits<5> RD;
  bits<20> IMM;

  let Inst{31-27} = RD;
  let Inst{26- 7} = IMM{19-0};
  let Inst{6 - 0} = op;
}

//J-Type, only 2 instructions no further consolidation
class InstJ<bits<7> op, dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstRISCV<4, outs, ins, asmstr, pattern> {
  field bits<32> Inst;

  bits<25> IMM;

  let Inst{31- 7} = IMM{24-0};
  let Inst{6 - 0} = op;
}

//===----------------------------------------------------------------------===//
// Pseudo instructions
//===----------------------------------------------------------------------===//
//
// Convenience instructions that get lowered to real instructions
// by either RISCVTargetLowering::EmitInstrWithCustomInserter()
// or RISCVInstrInfo::expandPostRAPseudo().
//
//===----------------------------------------------------------------------===//

class Pseudo<dag outs, dag ins, list<dag> pattern>
  : InstRISCV<0, outs, ins, "", pattern> {
  let isPseudo = 1;
  let isCodeGenOnly = 1;
}
