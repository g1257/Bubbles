

module Matrix;

import std.string;
import std.exception;
import std.array;
import std.stdio;

extern(C) void dsyev_(char *jobz,char *uplo,int *n,
    double *,int *, double *,double *,int *,int *);


class Matrix(T) {

public:
	
	this(size_t nrow,size_t ncol)
	{ 
		nrow_ = nrow;
		ncol_ = ncol;
		data_.length = nrow_*ncol_;
		for (int i=0;i<data_.length;i++)
			*(data_.ptr + i) = 0.0;
	}

	ref T opCall(size_t i,size_t j)
	{
		return *(data_.ptr + i + j*nrow_);
	}

	size_t n_row() const { return nrow_; } // legacy name
		
	size_t n_col() const { return ncol_; } // legacy name

	void resize(size_t nrow,size_t ncol)
	{
		assert(nrow_==0 && ncol_==0,
		  "Matrix::resize(...): matrix must be empty\n");
		reset(nrow,ncol);
	}

	void reset(size_t nrow,size_t ncol)
	{
		nrow_=nrow; ncol_=ncol;
		data_.length = nrow*ncol;
	}

	Matrix!(T) opBinary(string s)(Matrix!(T) rhs)
	{
		Matrix!(T) c = new Matrix!(T)(a.n_row(),a.n_col());
		for (size_t i=0;i<a.n_row();i++) {
			for (size_t j=0;j<a.n_col();j++) {
				static if (op == "+")  c(i,j) = a(i,j) + b(i,j);
				else static if (op == "-") c(i,j) = a(i,j) - b(i,j);
				else static assert(0, "Operator "~op~" not implemented");
			}
		}
		return c;
	}
	
	void print() const
	{
		for (size_t i=0;i<data_.length;i++) {
			T x = *(data_.ptr + i);
			writeln(x," ");
		}
	}

private:

	size_t nrow_,ncol_;
	T[] data_;

}

void diag1(T)(Matrix!T m,ref double[] eigs,char option)
{
	char jobz=option;
	char uplo='U';
	int n=cast(int)m.n_row();
	int lda=cast(int)m.n_col();
	double[] work;
	int info,lwork= -1;

	enforce(lda>0,"Expected lda>0\n");


	eigs.length=n;

	// query:
	work.length = 3;
	dsyev_(&jobz,&uplo,&n,&(m(0,0)),&lda, eigs.ptr,work.ptr,&lwork, &info);
	if (info!=0) {
		writeln("info=",info);
		assert(0,"diag: dsyev_: failed with info!=0.\n");
	}
	double x1 = *(work.ptr);
	lwork = cast(int)(x1);
	work.length = lwork+1;
	// real work:
	dsyev_(&jobz,&uplo,&n,&(m(0,0)),&lda, eigs.ptr,work.ptr,&lwork, &info);
	if (info!=0) {
		writeln("info=\n",info);
		assert(0,"diag: dsyev_: failed with info!=0.\n");
	}

}

// void diag(Matrix<std::complex<double> > &m,std::vector<double> &eigs,char option)
// {
// 	char jobz=option;
// 	char uplo='U';
// 	int n=m.n_row();
// 	int lda=m.n_col();
// 	std::vector<std::complex<double> > work(3);
// 	std::vector<double> rwork(3*n);
// 	int info,lwork= -1;
// 
// 	eigs.resize(n);
// 
// 	// query:
// 	zheev_(&jobz,&uplo,&n,&(m(0,0)),&lda,&(eigs[0]),&(work[0]),&lwork,&(rwork[0]),&info);
// 	lwork = int(real(work[0]))+1;
// 	work.resize(lwork+1);
// 	// real work:
// 	zheev_(&jobz,&uplo,&n,&(m(0,0)),&lda,&(eigs[0]),&(work[0]),&lwork,&(rwork[0]),&info);
// 	if (info!=0) {
// 		std::cerr<<"info="<<info<<"\n";
// 		throw std::runtime_error("diag: zheev: failed with info!=0.\n");
// 	}
// 
// }

	
