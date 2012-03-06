/*
Copyright (c) 2012, UT-Battelle, LLC
All rights reserved

[Bubbles, Version 0.1]
[by G.A., Oak Ridge National Laboratory]

UT Battelle Open Source Software License 11242008

OPEN SOURCE LICENSE

Subject to the conditions of this License, each
contributor to this software hereby grants, free of
charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), a
perpetual, worldwide, non-exclusive, no-charge,
royalty-free, irrevocable copyright license to use, copy,
modify, merge, publish, distribute, and/or sublicense
copies of the Software.

1. Redistributions of Software must retain the above
copyright and license notices, this list of conditions,
and the following disclaimer.  Changes or modifications
to, or derivative works of, the Software should be noted
with comments and the contributor and organization's
name.

2. Neither the names of UT-Battelle, LLC or the
Department of Energy nor the names of the Software
contributors may be used to endorse or promote products
derived from this software without specific prior written
permission of UT-Battelle.

3. The software and the end-user documentation included
with the redistribution, with or without modification,
must include the following acknowledgment:

"This product includes software produced by UT-Battelle,
LLC under Contract No. DE-AC05-00OR22725  with the
Department of Energy."
 
*********************************************************
DISCLAIMER

THE SOFTWARE IS SUPPLIED BY THE COPYRIGHT HOLDERS AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
COPYRIGHT OWNER, CONTRIBUTORS, UNITED STATES GOVERNMENT,
OR THE UNITED STATES DEPARTMENT OF ENERGY BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.

NEITHER THE UNITED STATES GOVERNMENT, NOR THE UNITED
STATES DEPARTMENT OF ENERGY, NOR THE COPYRIGHT OWNER, NOR
ANY OF THEIR EMPLOYEES, REPRESENTS THAT THE USE OF ANY
INFORMATION, DATA, APPARATUS, PRODUCT, OR PROCESS
DISCLOSED WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.

*********************************************************


*/
/** \ingroup DMRG */
/*@{*/

/*! \file CrsMatrix.h
 *
 *  A class to represent a sparse matrix in Compressed Row Storage
 *
 */

module CrsMatrix;



//! A Sparse Matrix in Compressed Row Storage (CRS) format.
/** 
The CRS format puts the subsequent nonzero elements of the matrix rows
in contiguous memory locations. We create 3 vectors: one for complex numbers containing the values of the
matrix entries 
and the other two for integers ($colind$ and $rowptr$).
The vector $values$ stores the values of the non-zero elements of the matrix,
as they are traversed in a row-wise fashion.
The $colind$ vector stores the column indices of the elements of the $values$
vector. That is, if $values[k] = a[i][j]$ then $colind[k] = j$.
The $rowptr$ vector stores the locations in the $values$ vector that start
a row, that is $values[k] = a[i][j]$ if $rowptr[i] \le i < rowptr[i + 1]$.
By convention, we define $rowptr[N_{dim}]$ to be equal to the number of non-zero elements,
$n_z$, in the matrix. The storage savings of this approach are significant since instead of
storing $N_{dim}^2$ elements, we need only $2n_z + N_{dim} + 1$ storage locations.\\
To illustrate how the CRS format works, consider the non-symmetric matrix defined by
\begin{equation}
	A=\left[\begin{tabular}{llllll}

	10 &  0 & 0 & 0  & -2 & 0 \\
	3 &  9 &  0 &  0 &  0 &  3 \\
	0 &  7 &  8 &  7 &  0 &  0 \\
	3 &  0 &  8 &  7  & 5 &  0 \\
	0 &   8 &  0 &  9 &  9 & 13 \\
	0 &  4 &  0 &  0 &  2&  -1 \\
\end{tabular}\right]\end{equation}
The CRS format for this matrix is then specified by the arrays:\\
\begin{tt}
	values = [10 -2  3  9  3  7  8  7  3 ... 9 13  4  2 -1 ]\\
	colind = [ 0  4  0  1  5  1  2  3  0 ... 4  5  1  4  5 ]\\
	rowptr = [ 0  2  5  8 12 16 19 ]\\
\end{tt}
*/

import Bubbles.Matrix;
import std.exception;
import std.complex;
import std.math;

T norm(T)(in T a)
{
	return fabs(a);
}

S norm(T : Complex!S) (in T a)
{
	return a.abs();
}


class CrsMatrix(T) {
public:
	alias T ValueType;

	this(size_t nrow,size_t ncol)
	{
		enforce(nrow==ncol,"CrsMatrix: only works for square matrices.\n");
		resize(nrow);
	}


	this(const Matrix!T a,double eps=0)
	{
		resize(a.n_row());	

		size_t counter=0;
		for (size_t i = 0; i < a.n_row(); i++) {
			setRow(i,counter);
			for (size_t j=0;j<a.n_col();j++) {
				if (norm(a(i,j))<=eps) continue;
				pushValue(a(i,j));
				pushCol(j);
				counter++;
			}

		}
		setRow(a.n_row(),counter);
	}

	void resize(size_t nsize)
	{
		colind_.length=0;
		values_.length=0;
		rowptr_.length=nsize+1;
	}

	void clear()
	{
		colind_.length=0;
		values_.length=0;
		rowptr_.length=0;
	}

	// Obsolete, do not use:
// 	void resize(size_t nsize,size_t nonzero) 
// 	{
// 		resize(nsize);
// 		colind_.resize(nonzero);
// 		values_.resize(nonzero);
// 	}

	void setRow(size_t n,size_t v) 
	{
		rowptr_[n]=v;
	}

	void setCol(size_t n,size_t v)
	{
		colind_[n]=v;
	}

	void setValues(size_t n,const ref T v)
	{
		values_[n]=v;
	}

// 		void operator*=(T x)
// 		{
// 			for (size_t i=0;i<values_.size();i++) values_[i] *= x;
// 		}
// 
// 		template<typename VerySparseMatrixType>
// 		void operator=(const VerySparseMatrixType& m)
// 		{
// 			resize(m.rank());
// 			size_t counter=0;
// 
// 			for (size_t i=0;i<m.rank();i++) {
// 				setRow(i,counter);
// 				size_t counter2=0;
// 				for (size_t j=counter;j<m.nonZero();j++) {
// 					if (m.getRow(j)!=i) break;
// 					pushCol(m.getColumn(j));
// 					pushValue(m.getValue(j));
// 					counter2++;
// 				}
// 				counter+=counter2;
// 				
// 			}
// 			setRow(m.rank(),counter);
// 		}
// 
// 		void operator+=(CrsMatrix<T> const &m) 
// 		{
// 			CrsMatrix<T> c;
// 			if (size_t(this->size_)>=m.rank()) operatorPlus(c,*this,m);
// 			else operatorPlus(c,m,*this);
// 			*this =c;
// 		}
// 
// 		T operator()(int i,int j) const 
// 		{
// 			for (int k=rowptr_[i];k<rowptr_[i+1];k++) if (colind_[k]==j) return values_[k];
// 			return static_cast<T>(0.0);
// 		}

	size_t nonZero() const { return colind_.length; }		

	/** performs x = x + A * y
	** where x and y are vectors and A is a sparse matrix in
	** row-compressed format */
	void matrixVectorProduct(S) (S[] x, const S[] y) const
	{ 
		for (size_t i = 0; i < y.length; i++)
			for (size_t j = rowptr_[i]; j < rowptr_[i + 1]; j++)
				x[i] += values_[j] * y[colind_[j]];
	}
	

	size_t rank() const { return (rowptr_.length==0) ? 0 :rowptr_.length -1; }

	//! This could be costly, a new array will be allocated
	void pushCol(size_t i) { colind_ ~= i; } 

	//! This could be costly, a new array will be allocated
	void pushValue(in T value) { values_ ~= value; }

	//! Make a diagonal CRS matrix with value "value"
	void makeDiagonal(size_t rank,ref const T value) 
	{
		rowptr_.length = rank + 1;
		values_.length = rank;
		colind_.length = rank;

		for (size_t i=0;i<rank;i++) {
			values_[i]=value;
			colind_[i]=i;
			rowptr_[i]=i;
		}
		rowptr_[rank]=rank;
	}

	size_t getRowPtr(size_t i) const 
	{
		assert(i<rowptr_.length,"CrsMatrix::getRowPtr\n");
		return rowptr_[i];
	}

	size_t getCol(size_t i) const
	{
		return colind_[i];
	}

	T getValue(size_t i) const
	{
		return values_[i];
	}

		/*bool operator==(const CrsMatrix<T>& B) const
		{
			if (!utils::vectorEqual(values_,B.values_)) return false;
			if (!utils::vectorEqual(colind_,B.colind_)) return false;
			if (!utils::vectorEqual(rowptr_,B.rowptr_)) return false;
			return true;
		}*/

	void set(const size_t[] rowptr,const size_t[] colind,const T[] values)
	{
		rowptr_=rowptr.dup;
		colind_=colind.dup;
		values_=values.dup;
	}

		void checkValidity() const
		{
			enum isDebug = 0;
			debug {
				isDebug = 1;
			}
			static if (!isDebug) return;
			
			assert(rowptr_.length>0);
			size_t n = rowptr_.length;
			for (size_t i=0;i<n;i++) {
				size_t[] p;
				p.length = n;
				p[] = 0;
				for (size_t k=rowptr_[i];k<rowptr_[i+1];k++) {
					size_t col = colind_[k];
					assert(p[col]==0,"CheckValidity\n");
					p[col] = 1;
				}
			}
		}
		
// 		template<typename S>
// 		friend std::ostream &operator<<(std::ostream &os,const CrsMatrix<S> &m);
// 		
// 		template<typename S,typename S2>
// 		friend void multiplyScalar(CrsMatrix<S> &ret,CrsMatrix<S> const &s,S2 const &v);
// 		
// 		template<class S>
// 		friend void difference(const CrsMatrix<S>& A,const CrsMatrix<S>& B);
// 
// 		template<typename S>
// 		friend void MpiBroadcast(CrsMatrix<S> *v,int rank);
// 	
// 		template<typename S>
// 		friend void MpiSend(CrsMatrix<S>  *v,int iproc,int i);
// 	
// 		template<typename S>
// 		friend void MpiRecv(CrsMatrix<S> *v,int iproc,int i);
// 		
// 		template<typename CrsMatrixType>
// 		friend std::istream &operator>>(std::istream &is,CrsMatrix<CrsMatrixType>& m);

	private:
		size_t[] rowptr_;
		size_t[] colind_;
		T[] values_;
	}; // class CrsMatrix

	// Companion functions below:

	/+template<typename T>
	std::ostream &operator<<(std::ostream &os,const CrsMatrix<T> &m)
	{
		size_t n=m.rank();
		if (n==0) return os;
		os<<n<<"\n";
		for (size_t i=0;i<n+1;i++) os<<m.rowptr_[i]<<" ";
		os<<"\n";
		
		size_t nonzero=m.nonZero();
		os<<nonzero<<"\n";
		for (size_t i=0;i<nonzero;i++) os<<m.colind_[i]<<" ";
		os<<"\n";
		
		os<<nonzero<<"\n";
		for (size_t i=0;i<nonzero;i++) os<<m.values_[i]<<" ";
		os<<"\n";
		
		return os;
	}

	template<typename T>
	std::istream &operator>>(std::istream &is,CrsMatrix<T>& m)
	{
		int n;
		is>>n;
		if (n<0) throw std::runtime_error(
				"is>>CrsMatrix(...): Rank must be positive\n");
		m.resize(n);
		for (size_t i=0;i<size_t(n)+1;i++) is>>m.rowptr_[i];

		size_t nonzero;
		is>>nonzero;
		m.colind_.resize(nonzero);
		for (size_t i=0;i<nonzero;i++) is>>m.colind_[i];

		is>>nonzero;
		m.values_.resize(nonzero);
		for (size_t i=0;i<nonzero;i++) is>>m.values_[i];

		return is;
	}+/

	//! Transforms a Compressed-Row-Storage (CRS) into a full Matrix (Fast version)
	void crsMatrixToFullMatrix(T)(Matrix!T m,const CrsMatrix!T crsMatrix)
	{
		size_t n=crsMatrix.rank();

		m.reset(n,n);
		for (size_t i = 0; i < n ; i++) {
			for (size_t k=0;k<n;k++) m(i,k)=0;
			for (size_t k=crsMatrix.getRowPtr(i);k<crsMatrix.getRowPtr(i+1);k++) 
				m(i,crsMatrix.getCol(k))=crsMatrix.getValue(k);
		}
	}

	
	//! Transforms a full matrix into a Compressed-Row-Storage (CRS) Matrix
	// Use the constructor if possible
	void fullMatrixToCrsMatrix(T)(CrsMatrix!T crsMatrix, const Matrix!T a)
	{
		size_t n=a.n_row();
		
		enforce(n==a.n_col(),"fullMatrixToCrsMatrix: only works for square matrices.\n");
			
		crsMatrix.resize(n);	
		
		size_t counter=0;
		for (size_t i = 0; i < n; i++) {
			crsMatrix.setRow(i,counter);
			for (size_t j=0;j<n;j++) {
				if (a(i,j)==0.0) continue;
				crsMatrix.pushValue(a(i,j));
				crsMatrix.pushCol(j);
				counter++;
			}
		}
		crsMatrix.setRow(n,counter);
	} 

	/+
	/** If order==false then 
	    creates B such that B_{i1+j1*nout,i2+j2*nout)=A(j1,j2)\delta_{i1,i2}
	    if order==true then
	    creates B such that B_{i1+j1*na,i2+j2*na)=A(i1,i2)\delta_{j1,j2}
	    where na=rank(A)
	  */
	template<class T>
	void externalProduct(CrsMatrix<T>  &B,CrsMatrix<T> const &A,int nout,
		std::vector<double> const &signs,bool order=true)
	{
		int na=A.rank();
		T tmp;

		B.resize(na*nout); //,nonzero*nout);

		int i,ii,jj,alpha,k,j,beta;
		int counter=0;
		for (ii=0;ii<na*nout;ii++) {
			if (order) {
				// ii = i+alpha*na;
				alpha = int(ii/na);
				i = ii-alpha*na;
			} else {
				//ii = alpha + i*nout;
				i = int(ii/nout);
				alpha = ii - i*nout;
			}
			B.setRow(ii,counter);
			for (k=A.getRowPtr(i);k<A.getRowPtr(i+1);k++) {
				j = A.getCol(k);
				beta=alpha;
				if (order) jj = j+beta*na;
				else       jj = beta+j*nout;
				//B.setCol(counter,jj);
				B.pushCol(jj);
				tmp = A.getValue(k);
				if (!order) tmp*=signs[alpha];
				//B.setValues(counter,tmp);
				B.pushValue(tmp);
				counter++;
			}
		}
		B.setRow(na*nout,counter);
	}

	//! Computes C = A external product B
	template<class T>
	void externalProduct(CrsMatrix<T>  &C,CrsMatrix<T> const &A,CrsMatrix<T> const &B)
	{
		int n=A.getSize()*B.getSize();
		C.resize(n);
		int na = A.getSize();
		T tmp;
		int i,k,kk,alpha,beta,j,counter=0;

		for (i=0;i<n;i++) {
			C.setRow(i,counter);
			// i = alpha + beta * na
			beta = int(i/na);
			alpha = i - beta * na;
			for (k=A.getRowPtr(alpha);k<A.getRowPtr(alpha+1);k++) {
				for (kk=B.getRowPtr(beta);kk<B.getRowPtr(beta+1);kk++) {
					j = A.getCol(k) + B.getCol(kk) *na;
					C.pushCol(j);
					tmp = A.getValue(k) * B.getValue(kk);
					C.pushValue(tmp);
					counter++;
				}
			}
		}
		C.setRow(n,counter);	
	}

	//! Computes C = A external product B (with signs)
	template<class T>
	void externalProduct(CrsMatrix<T>  &C,CrsMatrix<T> const &A,CrsMatrix<T> const &B,const std::vector<int>& signs,bool option=false)
	{
		int n=A.getSize()*B.getSize();
		C.resize(n);
		int na = A.getSize();
		T tmp;
		int i,k,kk,alpha,beta,j,counter=0;

		for (i=0;i<n;i++) {
			C.setRow(i,counter);
			// i = alpha + beta * na
			beta = int(i/na);
			alpha = i - beta * na;
			for (k=A.getRowPtr(alpha);k<A.getRowPtr(alpha+1);k++) {
				for (kk=B.getRowPtr(beta);kk<B.getRowPtr(beta+1);kk++) {
					j = A.getCol(k) + B.getCol(kk) *na;
					C.pushCol(j);
					int sign = signs[alpha];
					if (option) sign=signs[beta];
					tmp = A.getValue(k) * B.getValue(kk)*sign;
					C.pushValue(tmp);
					counter++;
				}
			}
		}
		C.setRow(n,counter);	
	}

	//! Sets ret = s * v where ret and s are CRS matrices and v is a scalar number
	template<typename S,typename T>
	void multiplyScalar(CrsMatrix<S> &ret,CrsMatrix<S> const &s,T const &v)
	{
		ret = s;
		for (size_t ii=0;ii<s.values_.size();ii++) {
			ret.values_[ii] *= v;
		}
	}

	template<typename T>
	void printFullMatrix(const CrsMatrix<T>& s,const std::string& name,size_t how=0,double eps = 1e-20)
	{
		PsimagLite::Matrix<T> fullm(s.rank(),s.rank());
		crsMatrixToFullMatrix(fullm,s);
		std::cout<<"--------->   "<<name<<" rank="<<s.rank()<<" <----------\n";
		try {
			if (how==1) mathematicaPrint(std::cout,fullm);
			if (how==2) symbolicPrint(std::cout,fullm);
		} catch (std::exception& e) {

		}

		if (how==0) fullm.print(std::cout,eps);

	}

	//! C = A*B,  all matrices are CRS matrices
	//! idea is from http://web.maths.unsw.edu.au/~farid/Papers/Hons/node23.html
	template<typename S,typename S2>
	void multiply(CrsMatrix<S> &C,CrsMatrix<S> const &A,CrsMatrix<S2> const &B,bool strict=true)
	{
		int j,s,mlast,itemp,jbk;
		size_t n = A.rank();
		std::vector<int> ptr(n,-1),index(n,0);
		std::vector<S> temp(n,0);
		S tmp;

		assert(!strict || n==B.rank());
		
		C.resize(n);
		
		// mlast pointer to the last place we updated in the C vector 
		mlast = 0;
		// for (size_t l=0;l<n;l++) ptr[l] = -1;
		// over the rows of A
		for (size_t i=0;i<n;i++) {
			C.setRow(i,mlast);
			// start calculations for row 
			itemp = 0;
			for(j = A.getRowPtr(i);j< A.getRowPtr(i+1);j++) { 
				size_t istart = B.getRowPtr(A.getCol(j));
				size_t iend = B.getRowPtr(A.getCol(j)+1);
				for (size_t k = istart; k< iend;k++) {
					jbk=B.getCol(k);
					tmp = A.getValue(j)*B.getValue(k);
					if( ptr[jbk]<0) {
						ptr[jbk] = itemp;
						temp[ptr[jbk]] = tmp ;
						index[ptr[jbk]] = jbk;
						itemp++;
					} else  {
						temp[ptr[jbk]]+= tmp;
			   		}
				}
			}
			// before you leave this row update array c , jc 	
			for (s=0;s<itemp;s++) {
				C.pushValue(temp[s]);
				C.pushCol(index[s]);
				ptr[index[s]]= -1;
			}
			mlast += itemp;
		}
		C.setRow(n,mlast);
	}

	// vector2 = sparseMatrix * vector1
	template<class S>
	void multiply(std::vector<S>& v2, const CrsMatrix<S>& m, const std::vector<S>& v1)
	{
		int i,j,n=m.rank();
		v2.resize(n);
		for (i=0;i<n;i++) {
			v2[i]=0;
			for (j=m.getRowPtr(i);j<m.getRowPtr(i+1);j++) {
				v2[i] += m.getValue(j)*v1[m.getCol(j)];
			}
		}
	}

	//! Sets B=transpose(conjugate(A))	
	template<typename S,typename S2>
	inline void transposeConjugate(CrsMatrix<S>  &B,CrsMatrix<S2> const &A)
	{
		int n=A.rank();
		int i,k;
		std::vector<std::vector<int> > col(n);
		std::vector<std::vector<S2> > value(n);

		// B(j,i) = conj(A(i,j))
		for (i=0;i<n;i++) {
			for (k=A.getRowPtr(i);k<A.getRowPtr(i+1);k++) {
				col[A.getCol(k)].push_back(i);
				S2 w = A.getValue(k);
				value[A.getCol(k)].push_back(w);
			}
		}

		B.resize(n); 

		int counter=0;
		for (i=0;i<n;i++) {
			
			B.setRow(i,counter);
			for (size_t j=0;j<col[i].size();j++) {
				if (value[i][j]==static_cast<S>(0.0)) continue;
				B.pushCol(col[i][j]);
				B.pushValue(std::conj(value[i][j]));
				counter++;
			}
		}
		B.setRow(n,counter);
	}

// 	template<class S>
// 	inline CrsMatrix<S> transposeConjugate(const CrsMatrix<S>& m)
// 	{
// 		CrsMatrix<S> temp;
// 		transposeConjugate(temp,m);
// 		return temp;
// 	}	

	//! Sets A = B(i,perm(j)), A and B CRS matrices	
	template<class S>
	void permute(CrsMatrix<S> &A,CrsMatrix<S> const &B,std::vector<size_t> const &perm)
	{
		int i,n = B.rank();

		A.resize(n);
		S tmp;

		std::vector<int> permInverse(n);
		for (i=0;i<n;i++) permInverse[perm[i]]=i;

		int k,counter=0;
		for (i=0;i<n;i++) {
			A.setRow(i,counter);
			for (k=B.getRowPtr(i);k<B.getRowPtr(i+1);k++) {
				A.pushCol(permInverse[B.getCol(k)]);
				tmp = B.getValue(k);
				A.pushValue(tmp);
				counter++;
			}
		}
		A.setRow(n,counter);
	}

	//! Sets A = B(perm(i),j), A and B CRS matrices		
	template<class S>
	void permuteInverse(CrsMatrix<S> &A,CrsMatrix<S> const &B,std::vector<size_t> const &perm)
	{
		int ii,n = B.rank();
		A.resize(n); // B.nonZero());
		S tmp;

		int k,counter=0;
		for (int i=0;i<n;i++) {
			ii = perm[i];
			A.setRow(i,counter);
			for (k=B.getRowPtr(ii);k<B.getRowPtr(ii+1);k++) {
				A.pushCol(B.getCol(k));
				tmp = B.getValue(k);
				A.pushValue(tmp);
				counter++;
			}
		}
		A.setRow(n,counter);
	}

	//! Sets A = B^\dagger * S * B
	template<class T>
	inline Matrix<T> transformFullFast(CrsMatrix<T> const &S,Matrix<T> const &fmB)
	{
		int nBig = S.rank();
		int nSmall = fmB.n_col();
		double alpha=1.0;
		double beta=0.0;
		Matrix<T> fmS,fmTmp(nBig,nSmall);
		
		crsMatrixToFullMatrix(fmS,S);

		psimag::BLAS::GEMM('N','N',nBig,nSmall,nBig,alpha,&(fmS(0,0)),nBig,&(fmB(0,0)),nBig,beta,&(fmTmp(0,0)),nBig);
		fmS.reset(nSmall,nSmall);
		psimag::BLAS::GEMM('C','N',nSmall,nSmall,nBig,alpha,&(fmB(0,0)),nBig,&(fmTmp(0,0)),nBig,beta,&(fmS(0,0)),nSmall);
		return fmS;
	}

	//! Sets A=B+C, restriction: B.size has to be larger or equal than C.size
	template<class T>
	void operatorPlus(CrsMatrix<T> &A,CrsMatrix<T> const &B,CrsMatrix<T> const &C)
	{
		size_t n = B.rank();
		T tmp;

		if (n<C.rank()) {
			std::cerr<<"B.size="<<B.rank()<<" C.size="<<C.rank()<<"\n";
			throw std::runtime_error("CrsMatrix<T>: operatorPlus: B.size must be larger or equal than C.size.\n");
		}

		std::vector<T>  valueTmp(n);
		std::vector<int> index;
		A.resize(n);

		size_t counter=0;
		for (size_t k2=0;k2<n;k2++) valueTmp[k2]= static_cast<T>(0.0);
		
		for (size_t i = 0; i < n; i++) {
			int k;
			A.setRow(i,counter);

			if (i<C.rank()) {
				// inspect this
				index.clear();
				for (k=B.getRowPtr(i);k<B.getRowPtr(i+1);k++) {
					if (B.getCol(k)<0 || size_t(B.getCol(k))>=n) throw std::runtime_error("operatorPlus (1)\n");
					valueTmp[B.getCol(k)]=B.getValue(k);
					index.push_back(B.getCol(k));
				}

				// inspect C 
				for (k=C.getRowPtr(i);k<C.getRowPtr(i+1);k++) {
					tmp = C.getValue(k);
					if (C.getCol(k)>=int(valueTmp.size()) || C.getCol(k)<0) throw std::runtime_error("operatorPlus (2)\n");

					valueTmp[C.getCol(k)] += tmp;
					index.push_back(C.getCol(k));
				}
				std::sort(index.begin(),index.end());
				k= -1;
				for (size_t kk=0;kk<index.size();kk++) {
					if (k==index[kk]) continue;
					k=index[kk];
					if (k<0 || size_t(k)>=n) throw std::runtime_error("operatorPlus (3)\n");
					tmp = valueTmp[k];
					if (tmp!=static_cast<T>(0.0)) {
						A.pushCol(k);
						A.pushValue(tmp);
						counter++;
						valueTmp[k]=static_cast<T>(0.0);
					}
				}
			} else {
				for (k=B.getRowPtr(i);k<B.getRowPtr(i+1);k++) {
					tmp = B.getValue(k);
					A.pushCol(B.getCol(k));
					A.pushValue(tmp);
					counter++;
				}
			}
		}
		A.setRow(n,counter);
	}

	template<typename T>
	bool isHermitian(const CrsMatrix<T>& A,bool doThrow=false)
	{
		for (size_t i=0;i<A.rank();i++) {
			for (int k=A.getRowPtr(i);k<A.getRowPtr(i+1);k++) {
				if (std::norm(A.getValue(k)-std::conj(A(A.getCol(k),i)))<1e-6) continue;
				assert(false);
				return false;
			}
		}
		return true;
	}

	template<class T>
	void sumBlock(CrsMatrix<T> &A,CrsMatrix<T> const &B,size_t offset)
	{
		int counter=0;
		CrsMatrix<T> Bfull;
		
		Bfull.resize(A.rank());
		for (size_t i=0;i<offset;i++) Bfull.setRow(i,counter);
		for (size_t ii=0;ii<B.rank();ii++) {
			size_t i=ii+offset;
			Bfull.setRow(i,counter);
			for (int jj=B.getRowPtr(ii);jj<B.getRowPtr(ii+1);jj++) {
				size_t j = B.getCol(jj)+offset;
				T tmp  = B.getValue(jj);
				Bfull.pushCol(j);
				Bfull.pushValue(tmp);
				counter++;
			}
		}
		//if (i>A.rank()) throw std::runtime_error("sumBlock\n");
		for (size_t i=B.rank()+offset;i<A.rank();i++) Bfull.setRow(i,counter);
		Bfull.setRow(A.rank(),counter);
		A += Bfull;
	}
	
	template<class T>
	bool isDiagonal(const CrsMatrix<T>& A) 
	{
		size_t n = A.getSize();
		for (size_t i=0;i<n;i++) for (size_t j=0;j<n;j++) if (i!=j && fabs(A(i,j))>1e-6) return false;	
		return true;
	}

	template<class T>
	bool isZero(const CrsMatrix<T>& A,double eps = 1e-6)
	{
		for (size_t i=0;i<A.rank();i++) {
			for (int k=A.getRowPtr(i);k<A.getRowPtr(i+1);k++) {
				double x = std::real(std::norm(A.getValue(k)));
				if (x>eps) {
					std::cerr<<"A("<<i<<","<<A.getCol(k)<<")="<<A.getValue(k)<<"\n";
					return false;
				}
			}
		}
		return true;
	}
	
	template<class T>
	bool isTheIdentity(const CrsMatrix<T>& A,double eps=1e-6) 
	{
		size_t n = A.rank();
		for (size_t i=0;i<n;i++) {
			for (int k=A.getRowPtr(i);k<A.getRowPtr(i+1);k++) {
				size_t col = A.getCol(k);
				const T& val = A.getValue(k);
				if (col==i && std::norm(val-1.0)>eps) {
					std::cerr<<"Diagonal is "<<val<<" at i="<<i<<"\n";
					return false;
				}
				if (col!=i && std::norm(val)>eps) {
					std::cerr<<"A("<<i<<","<<col<<")="<<val<<"\n";
					return false;
				}
			}
		}
		return true;
	}		

	template<typename T>
	Matrix<T> multiplyTc(const CrsMatrix<T>& a,const CrsMatrix<T>& b)
	{
		
		CrsMatrix<T> bb,c;
		transposeConjugate(bb,b);
		multiply(c,a,bb);
		Matrix<T> cc;
		crsMatrixToFullMatrix(cc,c);
		return cc;
	}

	template<typename T1,typename T2>
	CrsMatrix<T2> operator*(const T1& t1,const CrsMatrix<T2>& a)
	{
		CrsMatrix<T2> b;
		multiplyScalar(b,a,t1);
		return b;
	}

	template<typename T1,typename T2>
	CrsMatrix<T1> operator*(const CrsMatrix<T1>& a,const CrsMatrix<T2>& b)
	{
		CrsMatrix<T2> c;
		multiply(c,a,b);
		return c;
	}+/
		
/*@}*/	
