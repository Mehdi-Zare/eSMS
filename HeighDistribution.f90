program distribution

!**************************************************************************************************!
!               Author          :       Mehdi Zare                                                 !
!               date            :       02/01/2019                                                 !
!               Purpose         :       Height distribution of Water molecules from the metal      !
!                                       Surface                                                    !
!               Modification    :                                                                  !
!**************************************************************************************************!
implicit none

integer  ,  parameter                   ::      dp = selected_real_kind(15, 307)
integer                                 ::      alloc_err, ierror
integer                                 ::      nline, i, j, nBin
character(30)                           ::      OxygenZcoord
real(dp) ,  allocatable, dimension (:)  ::      Zcoord
real     ,  allocatable, dimension (:)  ::      Bins
real                                    ::      HZ, LZ, IZ, lowerbond, upperbond


!read the # of freq in freq.dat file
nline=0       ! The first line is Escf
open(100, file='OxygenZcoord', status='old', action = 'read', iostat = ierror)
do
 read (100, *, end=10)
 if (ierror /=0) exit
 nline=nline+1
end do
10 close(100)
write(*,*) 'nline= ', nline


allocate(Zcoord(nline))
open (unit=99, file = 'OxygenZcoord', status='old', action = 'read', iostat = ierror)
         do i=1,nline
                read(99,*, iostat = ierror) Zcoord(i)
                if (ierror /=0) exit
        end do
 close(99)

WRITE(*,*)'Length of Zcoord vecotr is',  SHAPE(Zcoord)

!Bins
!write(*,*) " Please enter the Z coordinate of the top of your box up to first digit"
!read (*,*) HZ
!write(*,*) " Please enter the Z coordinate of the top of your top metal layer up to first digit"
!read (*,*) LZ
!write(*,*) " Please enter the Bin interval up to first digit"
!read (*,*) IZ

HZ=49
LZ=6.9
IZ=0.1

nBin=((HZ-LZ)/IZ)+1+1 ! the first 1 because fortran round the number down, the
                        !second 1 for the bin above HZ
write(*,*) "nBin=" , nBin

allocate(Bins(nBin))

do j=1,nBin
       Bins(j)=0
end do

lowerbond=LZ
upperbond=lowerbond+IZ
do j=1,nBin
   do i=1,nline
      if ( Zcoord(i) >= lowerbond .AND. Zcoord(i) < upperbond  ) then
      Bins(j)=Bins(j)+1
      end if
   end do
   lowerbond=upperbond
   upperbond=lowerbond+IZ
end do


WRITE(*,*)'Length of Bins vecotr is',  SHAPE(Bins)

open    ( unit = 500, file = 'DISTRIBUTION', status = 'new')
!write    (500, 400)
!400 format ( 10x, "T          :     Temperature in Kelvin",/, 10x "deltaE     :
!Reaction energy in eV", &
!             /,10x,"deltaEF    :     Reaction Forward Energy in eV", &
!             /,10x,"deltaER    :     Reaction Reverse Energy in eV", &
!             /,10x,"deltaG     :     Reaction Free Energy in eV", &
!             /,10x,"deltaGF    :     Reaction Forwaed Free Energy in eV", &
!             /,10x,"deltaGR    :     Reaction Reverse Free Energy in eV",///)
!
write   ( 500, 501)
501 format ( 3x, "Bin-Number", 7x, "Population", 7x, "lowerBond", 7x, "upperBond")
write   (500,502)
502 format ( "===================================================================")

lowerbond=LZ
upperbond=lowerbond+IZ
do j=1,nBin
write   (500, 503) j , Bins(j), lowerbond, upperbond
503 format (3x, I5, 4x, F20.1, 7x, F5.1, 9x, F5.1)
lowerbond=upperbond
upperbond=lowerbond+IZ
end do
close(500)





deallocate(Zcoord, Bins, stat = alloc_err)
end program distribution
