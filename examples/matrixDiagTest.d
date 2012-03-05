import std.stdio;
import std.complex;

import Bubbles.Matrix;

int main()
{
	size_t nrow = 4;
	size_t ncol = nrow;

	alias Bubbles.Matrix.Matrix!(double) MatrixType;

	MatrixType m = new MatrixType(nrow,ncol);
 	m(0,0)=1.0; m(0,1)=-1.; m(1,0)=-1.; m(1,1)=2.;
	m(3,3)=3.2;
	writeln("Matrix is");
	m.print();
	double[] eigs;
 	diag1(m,eigs,'V');
	if (eigs.length==0) {
		writeln("eigs.length==0");
		return 1;
	}
	writeln("----------------------------");
	for (size_t i=0;i<eigs.length;i++) writeln(eigs[i]," ");
	writeln("----------------------------");
	alias Complex!double ComplexType;
	alias Bubbles.Matrix.Matrix!(ComplexType) MatrixCmplxType;
	MatrixCmplxType m2 = new MatrixCmplxType(nrow,ncol);
	m2(0,0)=1.0; m2(0,1)=ComplexType(0,-1);
	m2(1,0)=ComplexType(0,1); m2(1,1)=2.;
	m2(3,3)=3.2;
	writeln("Matrix is");
	m2.print();
	writeln("---------------------------");
	diag1(m2,eigs,'V');
	if (eigs.length==0) {
		writeln("eigs.length==0");
		return 1;
	}
	if (eigs.length==0) {
		writeln("eigs.length==0");
		return 1;
	}
	
	for (size_t i=0;i<eigs.length;i++) writeln(eigs[i]," ");
	writeln("Done!");
	return 0;
}

