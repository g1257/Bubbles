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

	SparseMatrixType sparse = new SparseMatrixType(rank,rank);
	fullMatrixToCrsMatrix(sparse,m);
	//sparse.opAssign!"*"(1.2);
	sparse*=1.2;

	MatrixType m2 =  new MatrixType(rank,rank);
	crsMatrixToFullMatrix(m2,sparse);

	m2.print();
	writeln("----------------\n");

	SparseMatrixType sparse2 = new SparseMatrixType(rank,rank);
	sparse2.makeDiagonal(rank,1);

	sparse2 += sparse;

	return 0;
}

