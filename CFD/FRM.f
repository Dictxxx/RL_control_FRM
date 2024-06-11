c-----------------------------------------------------------------------
C
C  USER SPECIFIED ROUTINES:
C
C     - boundary conditions
C     - initial conditions
C     - variable properties
C     - local acceleration for fluid (a)
C     - forcing function for passive scalar (q)
C     - general purpose routine for checking errors etc.
C
c-----------------------------------------------------------------------

c data extraction using interpolation (there is must not comment at the End of define sentence)
#define INTP_NMAX 601
#define INTP_NMAX2 25
#define INTP_NMAX3 1

c mesh dimensions
#define PI (4.*atan(1.))


c-----------------------------------------------------------------------
      subroutine uservp (ix,iy,iz,ieg)
      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'

      udiff  = 0.
      utrans = 0.
      ! the following should be global variables

      return
      end
c-----------------------------------------------------------------------
      subroutine userf  (ix,iy,iz,ieg)
      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'

      ffx = 0.0
      ffy = 0.0
      ffz = 0.0

      return
      end
c-----------------------------------------------------------------------
      subroutine userq  (ix,iy,iz,ieg)
      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'

      qvol   = 0.0
      source = 0.0

      return
      end

c-----------------------------------------------------------------------
      subroutine userchk
      include 'SIZE'
      include 'TOTAL'
      include 'ZPER'     ! for nelx,nely,nelz
      include 'JETVAR'
      
      parameter (lt=lx1*ly1*lz1*lelv)
      common /scrns/ vort(lt,3), wo1(lt), wo2(lt),
     &           coef(lx1,ly1,lz1,lelv)
      real vtmp(lx1*ly1*lz1*lelt,ldim),ptmp(lx1*ly1*lz1*lelt)
      character*132 restartf, filename

      real x0(3) ! Computes torque about the point x0 
      save x0
      data x0 /3*0/
      real x1(3) ! Computes torque about the point x1 
      save x1
      data x1 /5,0,0/

      real    rwk(INTP_NMAX,ldim+1) ! r,s,t,dist2
      integer iwk(INTP_NMAX,3)      ! code,proc,e1
      save    rwk,iwk

      real    rwk2(INTP_NMAX3,ldim+1) ! r,s,t,dist2
      integer iwk2(INTP_NMAX3,3)      ! code,proc,e1
      save    rwk2,iwk2

      integer nint,intp_h1,intp_h2,intp_h3,intp_h4
      save    nint,intp_h1,intp_h2,intp_h3,intp_h4
      integer intp_h
      save    intp_h
      integer i

      logical iffpts
      save    iffpts

      real xint(INTP_NMAX),yint(INTP_NMAX),zint(INTP_NMAX)
      save xint,yint,zint

      real preye(INTP_NMAX),intvx(INTP_NMAX),intvy(INTP_NMAX)
      save preye,intvx,intvy

      real sx0(1), sy0(1), sx_new(1), sy_new(1), sx_c(1), sy_c(1)
      save sx0, sy0, sx_new, sy_new
      
      real kx1(1), kx2(1), kx3(1), kx4(1)
      real ky1(1), ky2(1), ky3(1), ky4(1)
      real sx1(1), sx2(1), sx3(1)
      real sy1(1), sy2(1), sy3(1)
      real h, sz(1)
      real kx_p(1), ky_p(1)

      if (nid.eq.0) then
         open (223, file = 'Q.txt', status = 'old')
         ! read(223,*) Qnow1, Qnow2, Qnow3, Qnow4
         read(223,*) Qnow1, Qnow2
         close(223)
      endif
      call bcast(Qnow1,sizeof(Qnow1))
      call bcast(Qnow2,sizeof(Qnow2))
      ! call bcast(Qnow3,sizeof(Qnow3))
      ! call bcast(Qnow4,sizeof(Qnow4))

      ! if (istep.eq.0) then
      !    if (nid.eq.0) then
      !       open (223, file = 'Q.txt', status = 'old')
      !       read(223,*) Qnow
      !       close(223)
      !    endif
      ! else
      !    Qnow = 0.0
      ! endif
      ! call bcast(Qnow,sizeof(Qnow))
      
      !-------- RK4 to get the trajectory --------!
      if (istep == 0) then
         if (nid.eq.0) then
            open (225, file = 'trajectory_init.plt', status = 'old')
            read(225,*) sx0, sy0
            close(225)
            call cfill(sz,ZCINT,size(sz))

            open (unit=62, file='trajectory_hist_t.dat',
     $         status='replace', action='write')
            close(62)
         endif
         
         !---- setup interp ----!
         nxm = 1
         nint = INTP_NMAX3

         call interp_setup(intp_h1,0.0,nxm,nelt)
         iffpts = .true.   ! dummy call to find points
         call interp_nfld(kx1,vx,1,sx0,sy0,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h1)
         call interp_nfld(ky1,vy,1,sx0,sy0,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h1)
         iffpts = .false.
         call interp_nfld(kx1,vx,1,sx0,sy0,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h1)
         call interp_nfld(ky1,vy,1,sx0,sy0,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h1)
         if (nid.eq.0) then
            open (225, file = 'trajectory_init.plt', status = 'replace')
            write(225,*) sx0, sy0, kx1, ky1
            close(225)
         endif
      endif
      
      h = dt
      !---- RK4: 1st stage ----!
      if (istep.GE.1) then

      call interp_setup(intp_h1,0.0,nxm,nelt)
      iffpts = .true.   ! dummy call to find points
      call interp_nfld(kx1,vx,1,sx0,sy0,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h1)
      call interp_nfld(ky1,vy,1,sx0,sy0,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h1)
      iffpts = .false.
      call interp_nfld(kx1,vx,1,sx0,sy0,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h1)
      call interp_nfld(ky1,vy,1,sx0,sy0,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h1)
      ! sx_new = kx1*h + sx0
      ! sy_new = ky1*h + sy0
      sx1 = kx1*0.5*h + sx0
      sy1 = ky1*0.5*h + sy0
      
      !---- RK4: 2nd stage ----!
      call interp_setup(intp_h2,0.0,nxm,nelt)
      iffpts = .true.   ! dummy call to find points
      call interp_nfld(kx2,vx,1,sx1,sy1,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h2)
      call interp_nfld(ky2,vy,1,sx1,sy1,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h2)
      iffpts = .false. 
      call interp_nfld(kx2,vx,1,sx1,sy1,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h2)
      call interp_nfld(ky2,vy,1,sx1,sy1,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h2)
      sx2 = kx2*0.5*h + sx0
      sy2 = ky2*0.5*h + sy0

      !---- RK4: 3rd stage ----!
      call interp_setup(intp_h3,0.0,nxm,nelt)
      iffpts = .true.   ! dummy call to find points
      call interp_nfld(kx3,vx,1,sx2,sy2,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h3)
      call interp_nfld(ky3,vy,1,sx2,sy2,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h3)
      iffpts = .false. 
      call interp_nfld(kx3,vx,1,sx2,sy2,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h3)
      call interp_nfld(ky3,vy,1,sx2,sy2,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h3)
      sx3 = kx3*h + sx0
      sy3 = ky3*h + sy0
      kx4 = kx3
      ky4 = ky3

      !---- RK4: final stage ----!
      call interp_setup(intp_h4,0.0,nxm,nelt)
      iffpts = .true.   ! dummy call to find points
      call interp_nfld(kx3,vx,1,sx3,sy3,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h4)

      call interp_nfld(ky3,vy,1,sx3,sy3,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h4)
      iffpts = .false. 
      call interp_nfld(kx3,vx,1,sx3,sy3,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h4)
      call interp_nfld(ky3,vy,1,sx3,sy3,sz,nint,
     $                 iwk2,rwk2,INTP_NMAX3,iffpts,intp_h4)
      sx_new = (kx1+2.0*kx2+2.0*kx4+kx3)/6.0*h + sx0
      sy_new = (ky1+2.0*ky2+2.0*ky4+ky3)/6.0*h + sy0

      
!       if (nid.eq.0) then
!          open (unit=60, file='trajectory_hist.dat', status='old', 
!      $         action='write', position='append')
!          write(60,3) sx_new, sy_new
! 3        format(' ',6e17.9)
!          close(60)

!          open (unit=61, file='trajectory_k_hist.dat', status='old', 
!      $         action='write', position='append')
!          write(61,3) kx1, ky1
!          close(61)
!       endif

      ! if (istep==nsteps) then
      if (nid.eq.0) then
         open (unit=62, file='trajectory_hist_t.dat', status='old', 
     $         action='write', position='append')
3        format(' ',6e17.9)
         write(62,3) sx_new, sy_new, kx1, ky1
         close(62)
      endif
      ! endif

      sx0 = sx_new
      sy0 = sy_new

      endif


   !    !-------- Interpolate --------!
   !    if (istep == nsteps) then
   !       nxm = 1  ! mesh is linear
   !       call interp_setup(intp_h,0.0,nxm,nelt)
   !       nint = 0
   !       if (nid.eq.0) then
   !          nint = INTP_NMAX
   !          open (225, file = 'gamma_positions.plt', status = 'old')
   !          do i = 1,nint
   !             read(225,*)xint(i),yint(i) 
   !          enddo
   !          close(225)
   !          call cfill(zint,ZCINT,size(zint))
   !       endif
   !       iffpts = .true.   ! dummy call to find points
   !       call interp_nfld(intvx,vx,1,xint,yint,zint,nint,
   !   $                    iwk,rwk,INTP_NMAX,iffpts,intp_h)
   !       iffpts = .false.
   !       call interp_nfld(intvx,vx,1,xint,yint,zint,nint,
   !   $                    iwk,rwk,INTP_NMAX,iffpts,intp_h)
   !       iffpts = .true.   ! dummy call to find points
   !       call interp_nfld(intvy,vy,1,xint,yint,zint,nint,
   !   $                    iwk,rwk,INTP_NMAX,iffpts,intp_h)
   !       iffpts = .false.
   !       call interp_nfld(intvy,vy,1,xint,yint,zint,nint,
   !   $                    iwk,rwk,INTP_NMAX,iffpts,intp_h)

   !       if (nid.eq.0) then
   !       open(unit=60,file='gamma_values.dat')
   !       do i=1,INTP_NMAX
   !          write(60,3) xint(i),yint(i),intvx(i)
   !       enddo
   !       do i=1,INTP_NMAX
   !          write(60,3) xint(i),yint(i),intvy(i)
   !       enddo
   !       close(60)
   !       endif
   !    endif


      return
      end
c-----------------------------------------------------------------------
      subroutine userbc (ix,iy,iz,iside,ieg)
      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'
      include 'JETVAR'

      common /bcdata/ rstart   ! rstart is start of top layer of elements
      ! omega_old
      real :: pi_cons=3.1415926
      real :: az
      az=2*pi_cons/1080
      ! az = 0.125
      ! az_prime = az+Qnow*az
      ! az_prime = (1+Qnow)*az
      az_prime1 = Qnow1*az
      az_prime2 = Qnow2*az
      az_prime3 = Qnow3*az
      az_prime4 = Qnow4*az

      ! write(*,*)'==========', istep, az_prime, Qnow
       
      !-------- Extensional flow --------!
      if (x.gt.0.and.y.gt.0) then       ! cylinder located at (1,1,0)
         ux = -(y-1)*az_prime2                 ! counter-clockwise
         uy =  (x-1)*az_prime2
         uz =  0.0
      elseif (x.lt.0.and.y.gt.0) then   ! cylinder located at (-1,1,0)
         ux =  (y-1)*az_prime1                 ! clockwise
         uy = -(x+1)*az_prime1
         uz =  0.0
      elseif (x.lt.0.and.y.lt.0) then   ! cylinder located at (-1,-1,0)
         ux = -(y+1)*az                 ! counter-clockwise
         uy =  (x+1)*az
         uz =  0.0
      elseif (x.gt.0.and.y.lt.0) then   ! cylinder located at (1,-1,0)
         ux =  (y+1)*az                 ! clockwise
         uy = -(x-1)*az
         uz =  0.0     
      endif
      
      ! !-------- Rotational flow --------!
      ! if (x.gt.0.and.y.gt.0) then       ! cylinder located at (1,1,0)
      !    ux =  (y-1)*az                 ! clockwise
      !    uy = -(x-1)*az
      !    uz =  0.0
      ! elseif (x.lt.0.and.y.gt.0) then   ! cylinder located at (-1,1,0)
      !    ux =  (y-1)*az                 ! clockwise
      !    uy = -(x+1)*az
      !    uz =  0.0
      ! elseif (x.lt.0.and.y.lt.0) then   ! cylinder located at (-1,-1,0)
      !    ux =  (y+1)*az                 ! clockwise
      !    uy = -(x+1)*az
      !    uz =  0.0
      ! elseif (x.gt.0.and.y.lt.0) then   ! cylinder located at (1,-1,0)
      !    ux =  (y+1)*az                 ! clockwise
      !    uy = -(x-1)*az
      !    uz =  0.0     
      ! endif

      return
      end
c-----------------------------------------------------------------------
      subroutine useric (ix,iy,iz,ieg)
      include 'SIZE'
      include 'NEKUSE'      
      include 'INPUT'

      real amp, ran

c     velocity random distribution
      amp = UPARAM(1)         
      
      ran = 3.e4*(ieg+X*sin(Y)) - 1.5e3*ix*iy + .5e5*ix 
      ran = -1.e3*sin(ran)
      ran = 1.e3*sin(ran)
      ran = cos(ran)
      UX  = ran*amp
         
      ran = 2.3e4*(ieg+X*sin(Y)) + 2.3e3*ix*iy - 2.e5*ix 
      ran = 1.e3*sin(ran)
      ran = -1.e3*sin(ran)
      ran = cos(ran)
      UY  = ran*amp
         
      if (IF3D) then
         ran = 2.e4*(ieg+X*sin(Z)) + 2.3e3*ix*iz - 2.e5*ix 
         ran = 1.e3*sin(ran)
         ran = 1.e5*sin(ran)
         ran = cos(ran)
         UZ  = ran*amp 
      else
         UZ = 0
      endif

      temp = 0.0

      return
      end
c-----------------------------------------------------------------------
      subroutine usrdat   ! This routine to modify element vertices
      include 'SIZE'      ! _before_ mesh is generated, which 
      include 'TOTAL'     ! guarantees GLL mapping of mesh.

      return
      end
c-----------------------------------------------------------------------
      subroutine usrdat2   ! This routine to modify mesh coordinates
      include 'SIZE'
      include 'TOTAL'
      include 'ZPER'       ! for nelx,nely,nelz

      do iel=1,nelv
      do ifc=1,2*ndim
         id_face = bc(5,ifc,iel,1)
         if     (id_face.eq.1) then
            cbc(ifc,iel,1) = 'v  '    ! cylinder 1
         elseif (id_face.eq.2) then
            cbc(ifc,iel,1) = 'v  '    ! cylinder 2
         elseif (id_face.eq.3) then
            cbc(ifc,iel,1) = 'v  '    ! cylinder 3
         elseif (id_face.eq.4) then
            cbc(ifc,iel,1) = 'v  '    ! cylinder 4
         elseif (id_face.eq.5) then
            cbc(ifc,iel,1) = 'W  '
         elseif (id_face.eq.6) then
            cbc(ifc,iel,1) = 'W  '
         elseif (id_face.eq.7) then
            cbc(ifc,iel,1) = 'W  '

         endif
      enddo
      enddo


      call set_obj

      param(66) = 6
      param(67) = 6

      return
      end
c-----------------------------------------------------------------------
      subroutine usrdat3
      include 'SIZE'
      include 'TOTAL'

      return
      end

c-----------------------------------------------------------------------
      subroutine set_obj  ! define objects for surface integrals
      include 'SIZE'
      include 'TOTAL'

      integer e,f,eg

      nobj = 4                    ! the number of cylinders
      iobj = 0
      do ii=nhis+1,nhis+nobj
         iobj = iobj+1
         hcode(10,ii) = 'I'
         hcode( 1,ii) = 'F'
         hcode( 2,ii) = 'F'
         hcode( 3,ii) = 'F'
         lochis(1,ii) = iobj
      enddo
      nhis = nhis + nobj

      if (maxobj.lt.nobj) call exitti('increase maxobj in SIZE$',nobj)

      nxyz  = nx1*ny1*nz1
      nface = 2*ndim

      do e=1,nelv
      do f=1,nface
         if (cbc(f,e,1).eq.'v  ') then
            id_face = bc(5,f,e,1)
            if(id_face.eq.1) iobj = 1   ! cylinder 1
            if(id_face.eq.2) iobj = 2   ! cylinder 2
            if(id_face.eq.3) iobj = 3   ! cylinder 3
            if(id_face.eq.4) iobj = 4   ! cylinder 4
            if (iobj.gt.0) then
               nmember(iobj) = nmember(iobj) + 1
               mem = nmember(iobj)
               eg  = lglel(e)
               object(iobj,mem,1) = eg
               object(iobj,mem,2) = f
c              write(6,1) iobj,mem,f,eg,e,nid,' OBJ'
c   1          format(6i9,a4)
            endif
         endif
      enddo
      enddo

c     write(6,*) 'number',(nmember(k),k=1,4)

      return
      end
c-----------------------------------------------------------------------

c-----------------------------------------------------------------------
c automatically added by makenek
      subroutine usrsetvert(glo_num,nel,nx,ny,nz) ! to modify glo_num
      integer*8 glo_num(1)
      return
      end


c automatically added by makenek
      subroutine usrdat0() 

      return
      end

c automatically added by makenek
      subroutine userqtl

      call userqtl_scig

      return
      end
