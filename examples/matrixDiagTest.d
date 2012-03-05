import std.stdio;

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
	writeln("Trying...");
 	diag1(m,eigs,'V');
	if (eigs.length==0) {
		writeln("eigs.length==0");
		return 1;
	}
	writeln("Done!");
	for (size_t i=0;i<eigs.length;i++) writeln(eigs[i]," ");
	return 0;
}
