import std.stdio;
import std.complex;

import Bubbles.CrsMatrix;

alias Bubbles.CrsMatrix.CrsMatrix!(double) SparseMatrixType;
alias Bubbles.Matrix.Matrix!(double) MatrixType;

int main()
{
	size_t rank = 4;

	MatrixType m = new MatrixType(rank,rank);
 	m(0,0)=1.0; m(0,1)=-1.; m(1,0)=-1.; m(1,1)=2.;
	m(3,3)=3.2;

	SparseMatrixType sp = new SparseMatrixType(rank,rank);
	fullMatrixToCrsMatrix(sp,m);
	
	MatrixType m2 =  new MatrixType(rank,rank);
	crsMatrixToFullMatrix(m2,sp);

	m2.print();
	return 0;
}

