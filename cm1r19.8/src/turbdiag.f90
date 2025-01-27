  MODULE turbdiag_module

  implicit none

  private
  public :: turbdiag

  integer, parameter :: varmax = 10000

  integer, parameter :: fnums = 67
  integer, parameter :: fnumw = 68

  CONTAINS

!-------------------------------------------------------------------------------
!
!  turbdiag:  subroutine to calculate domain-wide diagnostics
!
!       Notes:  - reference profiles are domain-averages at height levels
!               - code currently does not account for terrain
!
!-------------------------------------------------------------------------------

    subroutine turbdiag(mtime,nwritet,trecs,trecw,qname,qunit,dt,dosfcflx,     &
                   xh,rxh,arh1,arh2,uh,ruh,xf,rxf,arf1,arf2,uf,ruf,            &
                   yh,vh,rvh,yf,vf,rvf,                                        &
                   xfref,yfref,rds,sigma,rdsf,sigmaf,                          &
                   wprof,ufrc,vfrc,thfrc,qvfrc,ug,vg,dvdr,                     &
                   uavg,vavg,thavg,pavg,qavg,cavg,cloudvar,                    &
                   tauh,taus,zh,mh,rmh,c1,c2,tauf,zf,mf,rmf,                   &
                   rho0s,pi0s,prs0s,rth0s,                                     &
                   pi0,rho0,prs0,thv0,th0,rth0,qv0,qc0,u0,v0,                  &
                   qi0,rr0,rf0,rrf0,                                           &
                   zs,gz,rgz,gzu,rgzu,gzv,rgzv,dzdx,dzdy,gx,gxu,gy,gyv,        &
                   tsk,znt,ust,tst,qst,z0t,z0q,thflux,qvflux,                  &
                   cd,ch,cq,u1,v1,s1,xland,psfc,tlh,prate,                     &
                   dum1,dum2,dum3,dum4,dum5,dum6,th  ,ql  ,                    &
                   divx,rho,rr,rf,prs,t11,t12,t13,t22,t23,t33,                 &
                   rru,u3d,up  ,utmp ,                                         &
                   rrv,v3d,vp  ,vtmp ,                                         &
                   rrw,w3d,wp  ,wtmp ,                                         &
                   pp3d,sadv,lenscl,qice,th3d,thv  ,thl   ,buoy  ,             &
                   q3d,qten,kmh,kmv,khh,khv,tkea,tke3d,tketen,                 &
                   nm,defv,defh,dissten,pt3d,                                  &
                   rain,hfx,qfx,u10,v10,s10,t2,q2,th2,                         &
                   hpbl,wspd,zol,mol,rmol,br,brcr,psim,psih,                   &
                   thpten,qvpten,qcpten,qipten,upten,vpten,xkzh,xkzq,xkzm,     &
                   qsfc,o30,zir,swten,lwten,swtenc,lwtenc,cldfra,              &
                   effc,effi,effs,effr,effg,effis,                             &
                   lwupt,lwuptc,lwdnt,lwdntc,lwupb,lwupbc,lwdnb,lwdnbc,        &
                   swupt,swuptc,swdnt,swdntc,swupb,swupbc,swdnb,swdnbc,        &
                   lwcf,swcf,                                                  &
                   tdiag,qdiag,udiag,vdiag,wdiag,kdiag,out2d,out3d,            &
                   getdbz,getvt,                                               &
                   sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,flag)
        ! end turbdiag
    use input
    use constants
    use cm1libs , only : rslf,rsif
    use getcape_module
    use mpi
    implicit none

    double precision, intent(in) :: mtime
    integer, intent(in) :: nwritet
    integer, intent(inout) :: trecs,trecw
    character(len=3), intent(in), dimension(maxq) :: qname
    character(len=20), intent(in), dimension(maxq) :: qunit
    real, intent(inout) :: dt
    logical, intent(in) :: dosfcflx
    real, intent(in), dimension(ib:ie) :: xh,rxh,arh1,arh2,uh,ruh
    real, intent(in), dimension(ib:ie+1) :: xf,rxf,arf1,arf2,uf,ruf
    real, intent(in), dimension(jb:je) :: yh,vh,rvh
    real, intent(in), dimension(jb:je+1) :: yf,vf,rvf
    real, intent(in), dimension(1-ngxy:nx+ngxy+1) :: xfref
    real, intent(in), dimension(1-ngxy:ny+ngxy+1) :: yfref
    real, intent(in), dimension(kb:ke) :: rds,sigma
    real, intent(in), dimension(kb:ke+1) :: rdsf,sigmaf
    real, intent(inout), dimension(kb:ke) :: wprof,ufrc,vfrc,thfrc,qvfrc,ug,vg,dvdr,  &
                                             uavg,vavg,thavg,pavg
    real, intent(inout), dimension(kb:ke,numq) :: qavg
    double precision, intent(inout), dimension(kb:ke,3+numq) :: cavg
    logical, intent(in), dimension(maxq) :: cloudvar
    real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: tauh,taus,zh,mh,rmh,c1,c2
    real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: tauf,zf,mf,rmf
    real, intent(in), dimension(ib:ie,jb:je) :: rho0s,pi0s,prs0s,rth0s
    real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: pi0,rho0,prs0,thv0,th0,rth0,qv0,qc0
    real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: u0
    real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: v0
    real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: qi0,rr0,rf0,rrf0
    real, intent(in), dimension(ib:ie,jb:je) :: zs
    real, intent(in), dimension(itb:ite,jtb:jte) :: gz,rgz,gzu,rgzu,gzv,rgzv,dzdx,dzdy
    real, intent(in), dimension(itb:ite,jtb:jte,ktb:kte) :: gx,gxu,gy,gyv
    real, intent(in), dimension(ib:ie,jb:je) :: tsk,znt,ust,tst,qst,z0t,z0q,thflux,qvflux,  &
                                                cd,ch,cq,u1,v1,s1,xland,psfc,tlh,prate
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: dum1,dum2,dum3,dum4,dum5,dum6,th,ql
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: divx,rho,rr,rf,prs
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: t11,t12,t13,t22,t23,t33
    real, intent(inout), dimension(ib:ie+1,jb:je,kb:ke) :: rru,u3d,utmp,up
    real, intent(inout), dimension(ib:ie,jb:je+1,kb:ke) :: rrv,v3d,vtmp,vp
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke+1) :: rrw,w3d,wtmp,wp
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: pp3d,sadv,lenscl,qice
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: th3d,thv,thl,buoy
    real, intent(inout), dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: q3d,qten
    real, intent(inout), dimension(ibc:iec,jbc:jec,kbc:kec) :: kmh,kmv,khh,khv
    real, intent(inout), dimension(ibt:iet,jbt:jet,kbt:ket) :: tkea,tke3d,tketen
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke+1) :: nm,defv,defh,dissten
    real, intent(in), dimension(ibp:iep,jbp:jep,kbp:kep,npt) :: pt3d
    real, intent(in), dimension(ib:ie,jb:je,nrain) :: rain
    real, intent(in), dimension(ibl:iel,jbl:jel) :: hfx,qfx,u10,v10,s10,t2,q2,th2
    real, intent(in), dimension(ibl:iel,jbl:jel) :: hpbl,wspd,zol,mol,rmol,br,brcr,psim,psih,qsfc
    real, intent(in), dimension(ibb:ieb,jbb:jeb,kbb:keb) :: thpten,qvpten,qcpten,qipten,upten,vpten
    real, intent(in), dimension(ibb:ieb,jbb:jeb,kbb:keb) :: xkzh,xkzq,xkzm
    real, intent(in), dimension(ibr:ier,jbr:jer,kbr:ker) :: o30
    real, intent(in), dimension(ibr:ier,jbr:jer) :: zir
    real, intent(in), dimension(ibr:ier,jbr:jer,kbr:ker) :: swten,lwten,swtenc,lwtenc,cldfra
    real, intent(in), dimension(ibr:ier,jbr:jer,kbr:ker) :: effc,effi,effs,effr,effg,effis
    real, intent(in), dimension(ibr:ier,jbr:jer) :: lwupt,lwuptc,lwdnt,lwdntc,lwupb,lwupbc,lwdnb,lwdnbc
    real, intent(in), dimension(ibr:ier,jbr:jer) :: swupt,swuptc,swdnt,swdntc,swupb,swupbc,swdnb,swdnbc
      real, intent(inout), dimension(ibr:ier,jbr:jer) :: lwcf,swcf
    logical, intent(in) :: getdbz,getvt
    real, intent(inout), dimension(cmp,jmp,kmp)   :: sw31,sw32,se31,se32
    real, intent(inout), dimension(imp,cmp,kmp)   :: ss31,ss32,sn31,sn32
    logical, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: flag
    real, intent(in) , dimension(ibdt:iedt,jbdt:jedt,kbdt:kedt,ntdiag) :: tdiag
    real, intent(in) , dimension(ibdq:iedq,jbdq:jedq,kbdq:kedq,nqdiag) :: qdiag
    real, intent(in) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nudiag) :: udiag
    real, intent(in) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nvdiag) :: vdiag
    real, intent(in) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nwdiag) :: wdiag
    real, intent(in) , dimension(ibdk:iedk,jbdk:jedk,kbdk:kedk,nkdiag) :: kdiag
    real, intent(inout), dimension(ib2d:ie2d,jb2d:je2d,nout2d) :: out2d
    real, intent(in) , dimension(ib3d:ie3d,jb3d:je3d,kb3d:ke3d,nout3d) :: out3d

    !---------------------------------------------------------------------------

    integer :: i,j,k,n,nvar,nvar2d,nfile,ncb,nrb,nlb,nct,nrt,nlt,nrk,diffit,nloop,nn,ntmp
    integer :: qflag,pdef,pdefweno
    real :: zi,zimin,zimax,dtdz,tmax,ustbar,zntbar,tem,tem1,nmavg,tk
    real :: qx,px,tx,tlcl,ee,tlast,prinv
    real, dimension(:), allocatable :: pfoo,tfoo,qfoo
    real :: zlcl, zlfc, zel , psource , tsource , qvsource
    double precision :: savg2d,temd,cwp,rwp,lwp,qcfrac,qrfrac,qlfrac,qifrac,qtfrac,    &
                        zibar,qcb,qrb,qlb,qct,qrt,qlt,weps,thfavg,qvfavg,wstmp,wstar,  &
                        fbmin,zfbmin,bfoo
    double precision, dimension(nk+1) :: savg,sfr,sfs,sfd,tmass,clw,cli,plw,pli
    double precision, dimension(nk+1) :: ufr,ufs,ufd,vfr,vfs,vfd,ptfr,ptfs,ptfd,qvfr,qvfs,qvfd
    real, dimension(0:nk+1) :: wavg,prsavg,piavg,thvavg,thlavg,rhoavg,rfavg,qcrit,  &
                               qvavg,qlavg,qtavg,wsp,wspa,stke,rtke,wvar,temavg,  &
                               u_hturb,u_vturb,u_hadv,u_vadv,u_pgrad,u_subs,u_cor,     &
                               v_hturb,v_vturb,v_hadv,v_vadv,v_pgrad,v_subs,v_cor,     &
                               w_hturb,w_vturb,w_hadv,w_vadv,w_pgrad,w_subs,w_buoy
    real, dimension(0:nk+1,npt) :: ptavg
    character(len=80) :: newstring
    character(len=80), dimension(varmax) :: varname,vardesc,varunit
    integer, dimension(varmax) :: varlvls
    character(len=1),  dimension(varmax) :: vargrid
    character(len=80) :: a1,a2
    character(len=16) :: a16
    logical :: saveit,doit,do2

    if( myid.eq.0 ) print *,' ..... begin turbdiag code ..... '

    uavg = 0.0
    vavg = 0.0
    wavg = 0.0
    prsavg = 0.0
    piavg = 0.0
    thvavg = 0.0
    thlavg = 0.0
    rhoavg = 0.0
    rfavg = 0.0
    qvavg = 0.0
    qlavg = 0.0
    qtavg = 0.0
    wsp = 0.0
    wspa = 0.0
    stke = 0.0
    rtke = 0.0
    wvar = 0.0

    sfr = 0.0
    sfs = 0.0
    sfd = 0.0

    ptfr = 0.0
    ptfs = 0.0
    ptfd = 0.0

    nvar = 0

    ! by default, assume 3d and scalar levels:
    varlvls = nk
    vargrid = 's'

    thfavg = 0.0
    qvfavg = 0.0
    fbmin = 0.0
    zfbmin = 0.0
    wstar = 0.0

    !---------------------------------------------------------------------------
    ! open file:

    IF( myid.eq.0 )THEN

        print *,'  nwritet = ',nwritet

        ! grads-format
        ! (by default, for now)

        newstring = string

        newstring(totlen+1:totlen+14) = '_turb_s.dat   '
        print *,newstring
        open(unit=fnums,file=newstring,form='unformatted',access='direct',recl=4)

        newstring(totlen+1:totlen+14) = '_turb_w.dat   '
        print *,newstring
        open(unit=fnumw,file=newstring,form='unformatted',access='direct',recl=4)

    ENDIF

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    ! misc prep:     th  =  potential temperature (theta)
    !                ql  =  total liquid water (usually qc+qr)

    IF( imoist.eq.0 )THEN
      ql = 0.0
      qice = 0.0
    ELSE
      do k=1,nk
        do j=1,nj
        do i=1,ni
          ql(i,j,k) = 0.0
        enddo
        enddo
        do n=nql1,nql2
        do j=1,nj
        do i=1,ni
          ql(i,j,k) = ql(i,j,k)+q3d(i,j,k,n)
        enddo
        enddo
        enddo
        if( iice.eq.1 )then
          do j=1,nj
          do i=1,ni
            qice(i,j,k) = 0.0
          enddo
          enddo
          do n=nqs1,nqs2
          do j=1,nj
          do i=1,ni
            qice(i,j,k) = qice(i,j,k)+q3d(i,j,k,n)
          enddo
          enddo
          enddo
        endif
      enddo
    ENDIF

    IF( imoist.eq.1 )THEN

      do k=1,nk
      do j=0,nj+1
      do i=0,ni+1
        th(i,j,k) = th0(i,j,k)+th3d(i,j,k)
        thv(i,j,k) = th(i,j,k)*(1.0+repsm1*q3d(i,j,k,nqv)-ql(i,j,k)-qice(i,j,k))
      enddo
      enddo
      enddo

    ELSE

      do k=1,nk
      do j=0,nj+1
      do i=0,ni+1
        th(i,j,k) = th0(i,j,k)+th3d(i,j,k)
        thv(i,j,k) = th(i,j,k)
      enddo
      enddo
      enddo

    ENDIF

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !  2d variables:

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'ust'
      vardesc(nvar) = 'surface friction velocity'
      varunit(nvar) = 'm/s'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( ust  ,savg2d)
      ustbar = savg2d
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'znt'
      vardesc(nvar) = 'surface roughness length'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( znt  ,savg2d)
      zntbar = max( 1.0e-10 , savg2d )
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

    if( sfcmodel.eq.2 .or. sfcmodel.eq.3 )then

      nvar = nvar+1
      varname(nvar) = 'z0t'
      vardesc(nvar) = 'surface roughness length for temperature'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( z0t  ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'z0q'
      vardesc(nvar) = 'surface roughness length for moisture'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( z0q  ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    endif

      !c-c-c-c-c-c-c-c-c-c

    if( sfcmodel.ge.1 )then
      nvar = nvar+1
      varname(nvar) = 'tsk'
      vardesc(nvar) = 'soil/ocean temperature'
      varunit(nvar) = 'K'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( tsk ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
    endif

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'psfc'
      vardesc(nvar) = 'pressure at surface'
      varunit(nvar) = 'Pa'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( psfc ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

    if( sfcmodel.ge.1 )then
      nvar = nvar+1
      varname(nvar) = 'qsfc'
      vardesc(nvar) = 'land/water water vapor mixing ratio'
      varunit(nvar) = 'g/g'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( qsfc ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
    endif

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'thflux'
      vardesc(nvar) = 'surface pot. temp. flux'
      varunit(nvar) = 'K m/s'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(thflux,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      thfavg = savg2d

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'qvflux'
      vardesc(nvar) = 'surface water vapor flux'
      varunit(nvar) = 'g/g m/s'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(qvflux,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      qvfavg = savg2d
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    sfcmodel1:  &
    IF( sfcmodel.ge.1 )THEN

      nvar = nvar+1
      varname(nvar) = 'hfx'
      vardesc(nvar) = 'surface sensible heat flux'
      varunit(nvar) = 'W/m2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(hfx,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qfx'
      vardesc(nvar) = 'surface latent heat flux'
      varunit(nvar) = 'W/m2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(qfx,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'u10'
    if( imove.eq.1 )then
      vardesc(nvar) = 'u component of 10m wind speed (ground-rel.)'
    else
      vardesc(nvar) = 'u component of 10m wind speed'
    endif
      varunit(nvar) = 'm/s'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( u10  ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'v10'
    if( imove.eq.1 )then
      vardesc(nvar) = 'v component of 10m wind speed (ground-rel.)'
    else
      vardesc(nvar) = 'v component of 10m wind speed'
    endif
      varunit(nvar) = 'm/s'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( v10  ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 's10'
    if( imove.eq.1 )then
      vardesc(nvar) = 'horiz wind speed at 10m (ground-rel.)'
    else
      vardesc(nvar) = 'horiz wind speed at 10m'
    endif
      varunit(nvar) = 'm/s'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( s10  ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 't2'
      vardesc(nvar) = 'diagnostic 2-m temperature'
      varunit(nvar) = 'K'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( t2  ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'q2'
      vardesc(nvar) = 'diagnostic 2-m mixing ratio'
      varunit(nvar) = 'g/g'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( q2  ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'th2'
      vardesc(nvar) = 'diagnostic 2-m potential temperature'
      varunit(nvar) = 'K'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( th2  ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'cd'
      vardesc(nvar) = 'drag coefficient'
      varunit(nvar) = 'nondimensional'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( cd ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'ch'
      vardesc(nvar) = 'surface exchange coefficient for sensible heat'
      varunit(nvar) = 'nondimensional'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( ch ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'cq'
      vardesc(nvar) = 'surface exchange coefficient for moisture'
      varunit(nvar) = 'nondimensional'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( cq ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

    ENDIF  sfcmodel1

      !c-c-c-c-c-c-c-c-c-c

    IF( ipbl.ge.1 .or. sfcmodel.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'hpbl'
    if( ipbl.eq.1 )then
      vardesc(nvar) = 'PBL height (from YSU scheme)'
    else
      vardesc(nvar) = 'estimated PBL height (based on bulk Ri)'
    endif
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( hpbl  ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    sfcstuff:  &
    IF( sfcmodel.ge.1 )THEN

      nvar = nvar+1
      varname(nvar) = 'wspd'
      vardesc(nvar) = 'sfc layer wind speed (with gust)'
      varunit(nvar) = 'm/s'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( wspd  ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'zol'
      vardesc(nvar) = 'z/L (z over Monin-Obukhov length)'
      varunit(nvar) = 'nondimensional'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( zol ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'br'
      vardesc(nvar) = 'bulk Richardson number in surface layer'
      varunit(nvar) = 'nondimensional'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( br ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'brcr'
      vardesc(nvar) = 'critical bulk Richardson number in surface layer'
      varunit(nvar) = 'nondimensional'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( brcr ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'psim'
      vardesc(nvar) = 'similarity stability function (momentum)'
      varunit(nvar) = 'nondimensional'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( psim ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'psih'
      vardesc(nvar) = 'similarity stability function (heat)'
      varunit(nvar) = 'nondimensional'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( psih ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'tst'
      vardesc(nvar) = 'theta-star (pot temp scaling parameter in similarity theory)'
      varunit(nvar) = 'nondimensional'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( tst ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'qst'
      vardesc(nvar) = 'q-star (water vapor scaling parameter in similarity theory)'
      varunit(nvar) = 'nondimensional'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( qst ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'mol'
      vardesc(nvar) = 'Monin-Obukhov length (L)'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      do j=1,nj
      do i=1,ni
        if( abs(rmol(i,j)).le.1.0e-10 )then
          dum1(i,j,1) = sign( 1.0e10 , rmol(i,j) )
        else
          dum1(i,j,1) = 1.0/rmol(i,j)
        endif
      enddo
      enddo
      call getavg2d( dum1(ib,jb,1) ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    ENDIF  sfcstuff

      !c-c-c-c-c-c-c-c-c-c

    ziflag:  &
    IF( testcase.ge.1 .and. testcase.le.7 )THEN

        zimin =  1.0e30
        zimax = -1.0e30
        do j=1,nj
        do i=1,ni
          zi = 0.0
          tmax = 0.0
          do k=nk,2,-1
            dtdz = (thv(i,j,k)-thv(i,j,k-1))*rdz*mf(i,j,k)
            if( dtdz .ge. tmax )then
              tmax = dtdz
              zi = zf(i,j,k)
            endif
          enddo
          dum1(i,j,1) = zi
          zimin = min( zimin , zi )
          zimax = max( zimax , zi )
        enddo
        enddo

      call MPI_ALLREDUCE(mpi_in_place,zimin,1,MPI_REAL,MPI_MIN,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(mpi_in_place,zimax,1,MPI_REAL,MPI_MAX,MPI_COMM_WORLD,ierr)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'zi'
      vardesc(nvar) = 'estimate of boundary-layer depth (max gradient method)'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d( dum1(ib,jb,1) ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      zibar = savg2d

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'zimin'
      vardesc(nvar) = 'minimum value of zi'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = zimin
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'zimax'
      vardesc(nvar) = 'maximum value of zi'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = zimax
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'zivar'
      vardesc(nvar) = 'variance of zi'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      do j=1,nj
      do i=1,ni
        dum1(i,j,2) = (dum1(i,j,1)-zibar)**2
      enddo
      enddo
      call getavg2d( dum1(ib,jb,2) ,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    ENDIF  ziflag

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN

      nvar = nvar+1
      varname(nvar) = 'rain'
      vardesc(nvar) = 'domain-averaged accum. rain at sfc'
      varunit(nvar) = 'cm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(rain(ib,jb,1),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN

      nvar = nvar+1
      varname(nvar) = 'prate'
      vardesc(nvar) = 'domain-averaged surface precipitatin rate'
      varunit(nvar) = 'kg/m2/s'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(prate(ib,jb),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN
      ! water paths, precipitable water:

      do j=1,nj
      do i=1,ni
        dum1(i,j,1) = 0.0
        dum1(i,j,2) = 0.0
        dum1(i,j,3) = 0.0
        dum1(i,j,4) = 0.0
        dum1(i,j,5) = 0.0
        dum2(i,j,1) = 0.0
        dum2(i,j,2) = 0.0
        dum2(i,j,3) = 0.0
        dum2(i,j,4) = 0.0
        dum2(i,j,5) = 0.0
      enddo
      enddo

      do k=1,nk
        if( nqc.ge.1 )then
          do j=1,nj
          do i=1,ni
            dum1(i,j,1) = dum1(i,j,1) + rho(i,j,k)*q3d(i,j,k,nqc)*dz*rmh(i,j,k)
          enddo
          enddo
        endif
        if( nqr.ge.1 )then
          do j=1,nj
          do i=1,ni
            dum1(i,j,2) = dum1(i,j,2) + rho(i,j,k)*q3d(i,j,k,nqr)*dz*rmh(i,j,k)
          enddo
          enddo
        endif
        do j=1,nj
        do i=1,ni
          dum1(i,j,3) = dum1(i,j,3) + rho(i,j,k)*ql(i,j,k)*dz*rmh(i,j,k)
        enddo
        enddo
        if( nqv.ge.1 )then
          do j=1,nj
          do i=1,ni
                                                                            ! 1000 kg/m3
            dum1(i,j,4) = dum1(i,j,4) + rho(i,j,k)*q3d(i,j,k,nqv)*dz*rmh(i,j,k)/1000.0
          enddo
          enddo
        endif
        do j=1,nj
        do i=1,ni
          dum1(i,j,5) = dum1(i,j,5) + rho(i,j,k)*rslf(prs(i,j,k),th(i,j,k)*(pi0(i,j,k)+pp3d(i,j,k)))*dz*rmh(i,j,k)
        enddo
        enddo
        IF( iice.eq.1 )THEN
          do j=1,nj
          do i=1,ni
            dum2(i,j,1) = dum2(i,j,1) + rho(i,j,k)*qice(i,j,k)*dz*rmh(i,j,k)
          enddo
          enddo
          if( nqi.ge.1 )then
            do j=1,nj
            do i=1,ni
              dum2(i,j,2) = dum2(i,j,2) + rho(i,j,k)*q3d(i,j,k,nqi)*dz*rmh(i,j,k)
            enddo
            enddo
          endif
          if( nqs.ge.1 )then
            do j=1,nj
            do i=1,ni
              dum2(i,j,3) = dum2(i,j,3) + rho(i,j,k)*q3d(i,j,k,nqs)*dz*rmh(i,j,k)
            enddo
            enddo
          endif
          if( nqg.ge.1 )then
            do j=1,nj
            do i=1,ni
              dum2(i,j,4) = dum2(i,j,4) + rho(i,j,k)*q3d(i,j,k,nqg)*dz*rmh(i,j,k)
            enddo
            enddo
          endif
          do j=1,nj
          do i=1,ni
            dum2(i,j,5) = dum2(i,j,5) + rho(i,j,k)*(ql(i,j,k)+qice(i,j,k))*dz*rmh(i,j,k)
          enddo
          enddo
        ENDIF
      enddo


      nvar = nvar+1
      varname(nvar) = 'cwp'
      vardesc(nvar) = 'cloud water path'
      varunit(nvar) = 'kg/(m^2)'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(dum1(ib,jb,1),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      cwp = savg2d

      nvar = nvar+1
      varname(nvar) = 'rwp'
      vardesc(nvar) = 'rain water path'
      varunit(nvar) = 'kg/(m^2)'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(dum1(ib,jb,2),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      rwp = savg2d

      nvar = nvar+1
      varname(nvar) = 'lwp'
      vardesc(nvar) = 'liquid water path (qc+qr)'
      varunit(nvar) = 'kg/(m^2)'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(dum1(ib,jb,3),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      lwp = savg2d

      nvar = nvar+1
      varname(nvar) = 'pwat'
      vardesc(nvar) = 'precipitable water'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(dum1(ib,jb,4),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'spwr'
      vardesc(nvar) = 'saturated water vapor path'
      varunit(nvar) = 'kg/(m^2)'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(dum1(ib,jb,5),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'fwp'
      vardesc(nvar) = 'frozen water (i.e., ice+snow+graup) path'
      varunit(nvar) = 'kg/(m^2)'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(dum2(ib,jb,1),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      cwp = savg2d

      nvar = nvar+1
      varname(nvar) = 'iwp'
      vardesc(nvar) = 'ice crystal water path'
      varunit(nvar) = 'kg/(m^2)'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(dum2(ib,jb,2),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      rwp = savg2d

      nvar = nvar+1
      varname(nvar) = 'swp'
      vardesc(nvar) = 'snow water path'
      varunit(nvar) = 'kg/(m^2)'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(dum2(ib,jb,3),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      lwp = savg2d

      nvar = nvar+1
      varname(nvar) = 'gwp'
      vardesc(nvar) = 'graupel/hail water path'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(dum2(ib,jb,4),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'tcwp'
      vardesc(nvar) = 'total condensate water path'
      varunit(nvar) = 'kg/(m^2)'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      call getavg2d(dum2(ib,jb,5),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'cwpvar'
      vardesc(nvar) = 'cloud water path variance'
      varunit(nvar) = 'kg^2/(m^4)'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      do j=1,nj
      do i=1,ni
        dum2(i,j,1) = (dum1(i,j,1)-cwp)**2
      enddo
      enddo
      call getavg2d(dum2(ib,jb,1),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'rwpvar'
      vardesc(nvar) = 'rain water path variance'
      varunit(nvar) = 'kg^2/(m^4)'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      do j=1,nj
      do i=1,ni
        dum2(i,j,2) = (dum1(i,j,2)-rwp)**2
      enddo
      enddo
      call getavg2d(dum2(ib,jb,2),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'lwpvar'
      vardesc(nvar) = 'liquid water path (qc+qr) variance'
      varunit(nvar) = 'kg^2/(m^4)'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      do j=1,nj
      do i=1,ni
        dum2(i,j,3) = (dum1(i,j,3)-lwp)**2
      enddo
      enddo
      call getavg2d(dum2(ib,jb,3),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN
      ! fraction of cloudy/rainy grid points:

      do j=1,nj
      do i=1,ni
        dum1(i,j,1) = 0.0
        dum1(i,j,2) = 0.0
        dum1(i,j,3) = 0.0
        dum1(i,j,4) = 0.0
        dum1(i,j,5) = 0.0
      enddo
      enddo

      do k=nk,1,-1
        ! use minimum of 1.0e-5 and 1% of saturation wrt liquid (using last known t,p)
        qcrit(k) = min( 1.0e-5 , 0.01*rslf(pavg(k),thavg(k)*((pavg(k)*rp00)**rovcp)) )
!!!        if( myid.eq.0 ) print *,'  qcrit: k,z,tavg,qcrit = ',k,zh(1,1,k),thavg(k)*((pavg(k)*rp00)**rovcp),qcrit(k)
        if( nqc.ge.1 )then
          do j=1,nj
          do i=1,ni
            if( q3d(i,j,k,nqc).ge.qcrit(k) ) dum1(i,j,1) = zh(i,j,k)
          enddo
          enddo
        endif
        if( nqr.ge.1 )then
          do j=1,nj
          do i=1,ni
            if( q3d(i,j,k,nqr).ge.qcrit(k) ) dum1(i,j,2) = zh(i,j,k)
          enddo
          enddo
        endif
        do j=1,nj
        do i=1,ni
          if( ql(i,j,k).ge.qcrit(k) ) dum1(i,j,3) = zh(i,j,k)
        enddo
        enddo
        if( iice.eq.1 )then
        do j=1,nj
        do i=1,ni
          if( qice(i,j,k).ge.qcrit(k) ) dum1(i,j,4) = zh(i,j,k)
        enddo
        enddo
        endif
        do j=1,nj
        do i=1,ni
          if( (ql(i,j,k)+qice(i,j,k)).ge.qcrit(k) ) dum1(i,j,5) = zh(i,j,k)
        enddo
        enddo
      enddo

      qcfrac = 0.0
      qrfrac = 0.0
      qlfrac = 0.0
      qifrac = 0.0
      qtfrac = 0.0

      do j=1,nj
      do i=1,ni
        if( dum1(i,j,1).gt.0.01*zh(1,1,1) ) qcfrac = qcfrac+1.0
        if( dum1(i,j,2).gt.0.01*zh(1,1,1) ) qrfrac = qrfrac+1.0
        if( dum1(i,j,3).gt.0.01*zh(1,1,1) ) qlfrac = qlfrac+1.0
        if( dum1(i,j,4).gt.0.01*zh(1,1,1) ) qifrac = qifrac+1.0
        if( dum1(i,j,5).gt.0.01*zh(1,1,1) ) qtfrac = qtfrac+1.0
      enddo
      enddo

      call MPI_ALLREDUCE(MPI_IN_PLACE,qcfrac,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,qrfrac,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,qlfrac,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,qifrac,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,qtfrac,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

      temd = 1.0d0/dble(nx*ny)

      qcfrac = qcfrac*temd
      qrfrac = qrfrac*temd
      qlfrac = qlfrac*temd
      qifrac = qifrac*temd
      qtfrac = qtfrac*temd

      nvar = nvar+1
      varname(nvar) = 'qcfrac_col'
      vardesc(nvar) = 'fraction of columns with cloud water'
      varunit(nvar) = 'dimensionless'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = qcfrac
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qrfrac_col'
      vardesc(nvar) = 'fraction of columns with rain water'
      varunit(nvar) = 'dimensionless'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = qrfrac
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qlfrac_col'
      vardesc(nvar) = 'fraction of columns with liquid (qc+qr)'
      varunit(nvar) = 'dimensionless'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = qlfrac
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qifrac_col'
      vardesc(nvar) = 'fraction of columns with ice (qs+qg+qi)'
      varunit(nvar) = 'dimensionless'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = qifrac
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qtfrac_col'
      vardesc(nvar) = 'fraction of columns with liquid+ice (qc+qr+qs+qg+qi)'
      varunit(nvar) = 'dimensionless'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = qtfrac
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      qcb = 0.0
      qrb = 0.0
      qlb = 0.0

      ncb = 0
      nrb = 0
      nlb = 0

      do j=1,nj
      do i=1,ni
        if( dum1(i,j,1).gt.0.01*zh(1,1,1) )then
          qcb = qcb+dum1(i,j,1)
          ncb = ncb+1
        endif
        if( dum1(i,j,2).gt.0.01*zh(1,1,1) )then
          qrb = qrb+dum1(i,j,2)
          nrb = nrb+1
        endif
        if( dum1(i,j,3).gt.0.01*zh(1,1,1) )then
          qlb = qlb+dum1(i,j,3)
          nlb = nlb+1
        endif
      enddo
      enddo

      call MPI_ALLREDUCE(MPI_IN_PLACE,qcb,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,qrb,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,qlb,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,ncb,1,MPI_INTEGER         ,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,nrb,1,MPI_INTEGER         ,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,nlb,1,MPI_INTEGER         ,MPI_SUM,MPI_COMM_WORLD,ierr)

      qcb = qcb/dble(max(1,ncb))
      qrb = qrb/dble(max(1,nrb))
      qlb = qlb/dble(max(1,nlb))

      nvar = nvar+1
      varname(nvar) = 'qcb'
      vardesc(nvar) = 'avg height of qc base'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = qcb
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qrb'
      vardesc(nvar) = 'avg height of qr base'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = qrb
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qlb'
      vardesc(nvar) = 'avg height of ql (=qc+qr) base'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = qlb
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'qcbvar'
      vardesc(nvar) = 'variance of height of qc base'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      do j=1,nj
      do i=1,ni
        dum2(i,j,1) = (dum1(i,j,1)-qcb)**2
      enddo
      enddo

      call getavg2d(dum2(ib,jb,1),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qrbvar'
      vardesc(nvar) = 'variance of height of qr base'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      do j=1,nj
      do i=1,ni
        dum2(i,j,2) = (dum1(i,j,2)-qrb)**2
      enddo
      enddo

      call getavg2d(dum2(ib,jb,2),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qlbvar'
      vardesc(nvar) = 'variance of height of ql (=qc+qr)base'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      do j=1,nj
      do i=1,ni
        dum2(i,j,3) = (dum1(i,j,3)-qlb)**2
      enddo
      enddo

      call getavg2d(dum2(ib,jb,3),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN
      ! cloud top heights:

      do j=1,nj
      do i=1,ni
        dum1(i,j,1) = 0.0
        dum1(i,j,2) = 0.0
        dum1(i,j,3) = 0.0
      enddo
      enddo

      do k=1,nk
        if( nqc.ge.1 )then
          do j=1,nj
          do i=1,ni
            if( q3d(i,j,k,nqc).ge.qcrit(k) ) dum1(i,j,1) = zh(i,j,k)
          enddo
          enddo
        endif
        if( nqr.ge.1 )then
          do j=1,nj
          do i=1,ni
            if( q3d(i,j,k,nqr).ge.qcrit(k) ) dum1(i,j,2) = zh(i,j,k)
          enddo
          enddo
        endif
        do j=1,nj
        do i=1,ni
          if( ql(i,j,k).ge.qcrit(k) ) dum1(i,j,3) = zh(i,j,k)
        enddo
        enddo
      enddo

      qct = 0.0
      qrt = 0.0
      qlt = 0.0

      nct = 0
      nrt = 0
      nlt = 0

      do j=1,nj
      do i=1,ni
        if( dum1(i,j,1).gt.0.01*zh(1,1,1) )then
          qct = qct+dum1(i,j,1)
          nct = nct+1
        endif
        if( dum1(i,j,2).gt.0.01*zh(1,1,1) )then
          qrt = qrt+dum1(i,j,2)
          nrt = nrt+1
        endif
        if( dum1(i,j,3).gt.0.01*zh(1,1,1) )then
          qlt = qlt+dum1(i,j,3)
          nlt = nlt+1
        endif
      enddo
      enddo

      call MPI_ALLREDUCE(MPI_IN_PLACE,qct,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,qrt,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,qlt,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,nct,1,MPI_INTEGER         ,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,nrt,1,MPI_INTEGER         ,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,nlt,1,MPI_INTEGER         ,MPI_SUM,MPI_COMM_WORLD,ierr)

      qct = qct/dble(max(1,nct))
      qrt = qrt/dble(max(1,nrt))
      qlt = qlt/dble(max(1,nlt))

      nvar = nvar+1
      varname(nvar) = 'qct'
      vardesc(nvar) = 'avg height of qc top'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = qct
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qrt'
      vardesc(nvar) = 'avg height of qr top'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = qrt
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qlt'
      vardesc(nvar) = 'avg height of ql (=qc+qr) top'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'
      savg2d = qlt
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'qctvar'
      vardesc(nvar) = 'variance of height of qc top'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      do j=1,nj
      do i=1,ni
        dum2(i,j,1) = (dum1(i,j,1)-qct)**2
      enddo
      enddo

      call getavg2d(dum2(ib,jb,1),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qrtvar'
      vardesc(nvar) = 'variance of height of qr top'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      do j=1,nj
      do i=1,ni
        dum2(i,j,2) = (dum1(i,j,2)-qrt)**2
      enddo
      enddo

      call getavg2d(dum2(ib,jb,2),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'qltvar'
      vardesc(nvar) = 'variance of height of ql (=qc+qr) top'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      do j=1,nj
      do i=1,ni
        dum2(i,j,3) = (dum1(i,j,3)-qlt)**2
      enddo
      enddo

      call getavg2d(dum2(ib,jb,3),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( testcase.eq.4 .or. testcase.eq.5 )THEN

      nvar = nvar+1
      varname(nvar) = 'zir'
      vardesc(nvar) = 'estimate of b.l. depth for simple rad. scheme'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d( zir ,savg2d)
      zibar = savg2d
      call write2d(zibar,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'zirvar'
      vardesc(nvar) = 'variance of zir'
      varunit(nvar) = 'm^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      do j=1,nj
      do i=1,ni
        dum2(i,j,1) = (zir(i,j)-zibar)**2
      enddo
      enddo

      call getavg2d(dum2(ib,jb,1),savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'lwupt'
      vardesc(nvar) = 'lw flux, upward, top of atmosphere (OLR)'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(lwupt,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'lwdnt'
      vardesc(nvar) = 'lw flux, downward, top of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(lwdnt,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'lwupb'
      vardesc(nvar) = 'lw flux, upward, bottom of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(lwupb,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'lwdnb'
      vardesc(nvar) = 'lw flux, downward, bottom of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(lwdnb,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'swupt'
      vardesc(nvar) = 'sw flux, upward, top of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(swupt,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'swdnt'
      vardesc(nvar) = 'sw flux, downward, top of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(swdnt,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'swupb'
      vardesc(nvar) = 'sw flux, upward, bottom of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(swupb,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'swdnb'
      vardesc(nvar) = 'sw flux, downward, bottom of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(swdnb,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'lwuptc'
      vardesc(nvar) = 'lw flux, upward, top of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(lwuptc,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'lwdntc'
      vardesc(nvar) = 'lw flux, downward, top of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(lwdntc,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'lwupbc'
      vardesc(nvar) = 'lw flux, upward, bottom of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(lwupbc,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'lwdnbc'
      vardesc(nvar) = 'lw flux, downward, bottom of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(lwdnbc,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'swuptc'
      vardesc(nvar) = 'sw flux, upward, top of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(swuptc,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'swdntc'
      vardesc(nvar) = 'sw flux, downward, top of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(swdntc,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'swupbc'
      vardesc(nvar) = 'sw flux, upward, bottom of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(swupbc,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'swdnbc'
      vardesc(nvar) = 'sw flux, downward, bottom of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(swdnbc,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'lwcf'
      vardesc(nvar) = 'longwave cloud forcing at top-of-atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(lwcf,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'swcf'
      vardesc(nvar) = 'shortwave cloud forcing at top-of-atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0
      vargrid(nvar) = '2'

      call getavg2d(swcf,savg2d)
      call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

      doit = .true.
      IF( doit )THEN
        IF( imoist.eq.1 )THEN

          ! cape, cin, lfc, lcl:

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k,pfoo,tfoo,qfoo,zel,psource,tsource,qvsource)
          DO j=1,nj
          DO i=1,ni

            allocate( pfoo(nk+1) )
            allocate( tfoo(nk+1) )
            allocate( qfoo(nk+1) )

            do k=1,nk
              pfoo(k+1) = 0.01*prs(i,j,k)
              tfoo(k+1) = (th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k)) - 273.15
              qfoo(k+1) = q3d(i,j,k,nqv)
            enddo

            pfoo(1) = cgs1*pfoo(2)+cgs2*pfoo(3)+cgs3*pfoo(4)
            tfoo(1) = cgs1*tfoo(2)+cgs2*tfoo(3)+cgs3*tfoo(4)
            qfoo(1) = cgs1*qfoo(2)+cgs2*qfoo(3)+cgs3*qfoo(4)

            ! dum1(1) = cape
            ! dum1(2) = cin
            ! dum2(1) = lcl
            ! dum2(2) = lfc

            call getcape( 3 , nk+1 , pfoo , tfoo , qfoo , dum1(i,j,1) , dum1(i,j,2) ,   &
                          dum2(i,j,1), dum2(i,j,2), zel , psource , tsource , qvsource )

            deallocate( pfoo )
            deallocate( tfoo )
            deallocate( qfoo )

          ENDDO
          ENDDO

          nvar = nvar+1
          varname(nvar) = 'cape'
          vardesc(nvar) = 'convective available potential energy'
          varunit(nvar) = 'J/kg'
          varlvls(nvar) = 0
          vargrid(nvar) = '2'
          call getavg2d(dum1(ib,jb,1),savg2d)
          call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

          nvar = nvar+1
          varname(nvar) = 'cin'
          vardesc(nvar) = 'convective inhibition'
          varunit(nvar) = 'J/kg'
          varlvls(nvar) = 0
          vargrid(nvar) = '2'
          call getavg2d(dum1(ib,jb,2),savg2d)
          call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

          nvar = nvar+1
          varname(nvar) = 'lcl'
          vardesc(nvar) = 'lifted condensation level'
          varunit(nvar) = 'm'
          varlvls(nvar) = 0
          vargrid(nvar) = '2'
          call getavg2d(dum2(ib,jb,1),savg2d)
          call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

          nvar = nvar+1
          varname(nvar) = 'lfc'
          vardesc(nvar) = 'level of free convection'
          varunit(nvar) = 'm'
          varlvls(nvar) = 0
          vargrid(nvar) = '2'
          call getavg2d(dum2(ib,jb,2),savg2d)
          call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ENDIF
      ENDIF

      !c-c-c-c-c-c-c-c-c-c

        !$omp parallel do default(shared)  &
        !$omp private(i,j,k,tx,tlast)
        do j=1,nj
        do i=1,ni
          tx = 1.0e30
          k = 1
          do while( tx.gt.273.15 .and. k.lt.nk )
            tlast = tx
            k = k + 1
            tx = (th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k))
          enddo
          dum1(i,j,1) = zh(i,j,k-1)+(zh(i,j,k)-zh(i,j,k-1))  &
                                   *(273.15-tlast)  &
                                   /(tx-tlast)
          dum1(i,j,2) = prs(i,j,k-1)+(prs(i,j,k)-prs(i,j,k-1))  &
                                    *(273.15-tlast)  &
                                    /(tx-tlast)
        enddo
        enddo

        nvar = nvar+1
        varname(nvar) = 'zmelt'
        vardesc(nvar) = 'height of melting level'
        varunit(nvar) = 'm'
        varlvls(nvar) = 0
        vargrid(nvar) = '2'
        call getavg2d(dum1(ib,jb,1),savg2d)
        call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'pmelt'
        vardesc(nvar) = 'pressure of melting level'
        varunit(nvar) = 'Pa'
        varlvls(nvar) = 0
        vargrid(nvar) = '2'
        call getavg2d(dum1(ib,jb,2),savg2d)
        call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar2d = nvar

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    ! 3d vars:  averages

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'u'
        vardesc(nvar) = 'u component of velocity (grid-relative)'
        varunit(nvar) = 'm/s'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = u3d(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save uavg:
        do k=1,nk
          uavg(k) = savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'v'
        vardesc(nvar) = 'v component of velocity (grid-relative)'
        varunit(nvar) = 'm/s'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = v3d(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save vavg:
        do k=1,nk
          vavg(k) = savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'w'
        vardesc(nvar) = 'vertical velocity'
        varunit(nvar) = 'm/s'
        vargrid(nvar) = 'w'
        call getavg3d(w3d(ib,jb,kb),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save wavg:
        do k=1,nk
          wavg(k) = savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'th'
        vardesc(nvar) = 'potential temperature'
        varunit(nvar) = 'K'
        call getavg3d(th,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save thavg:
        do k=1,nk
          thavg(k) = savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 't'
        vardesc(nvar) = 'temperature'
        varunit(nvar) = 'K'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = th(i,j,k)*(pi0(i,j,k)+pp3d(i,j,k))
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'prs'
        vardesc(nvar) = 'pressure'
        varunit(nvar) = 'Pa'
        call getavg3d(prs,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save prsavg:
        do k=1,nk
          prsavg(k) = savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'rho'
        vardesc(nvar) = 'dry air density'
        varunit(nvar) = 'kg/m3'

        call getavg3d(rho,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save rhoavg:
        do k=1,nk
          rhoavg(k) = savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'rho'
        vardesc(nvar) = 'dry air density'
        varunit(nvar) = 'kg/m3'
        vargrid(nvar) = 'w'

        call getavg3d(rf,savg,nk+1)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save rfavg:
        do k=1,nk+1
          rfavg(k) = savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'ppi'
        vardesc(nvar) = 'nondimensional pressure'
        varunit(nvar) = 'nondimensional'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = pi0(i,j,k)+pp3d(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save piavg:
        do k=1,nk
          piavg(k) = savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 )THEN
        ! mixing ratios:

        DO n=1,numq

          nvar = nvar+1
          varname(nvar) = qname(n)
          vardesc(nvar) = qname(n)
          varunit(nvar) = qunit(n)

          call getavg3d(q3d(ib,jb,kb,n),savg)
          call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

          if( n.eq.nqv )then
            ! save qvavg:
            do k=1,nk
              qvavg(k) = savg(k)
            enddo
          endif

        ENDDO

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      ! specific humidities:
      doit = .true.
      IF( doit .and. imoist.eq.1 )THEN

        DO n=1,numq

          do2 = .false.

          if( qname(n).eq.'qv ' )then
            do2 = .true.
            nvar = nvar+1
            varname(nvar) = 'shv'
            vardesc(nvar) = 'specific humidity (water vapor)'
            varunit(nvar) = 'g/g'
          endif
          if( qname(n).eq.'qc ' )then
            do2 = .true.
            nvar = nvar+1
            varname(nvar) = 'shc'
            vardesc(nvar) = 'specific humidity (cloud water)'
            varunit(nvar) = 'g/g'
          endif
          if( qname(n).eq.'qr ' )then
            do2 = .true.
            nvar = nvar+1
            varname(nvar) = 'shr'
            vardesc(nvar) = 'specific humidity (rain water)'
            varunit(nvar) = 'g/g'
          endif
          if( qname(n).eq.'qi ' )then
            do2 = .true.
            nvar = nvar+1
            varname(nvar) = 'shi'
            vardesc(nvar) = 'specific humidity (cloud ice)'
            varunit(nvar) = 'g/g'
          endif
          if( qname(n).eq.'qs ' )then
            do2 = .true.
            nvar = nvar+1
            varname(nvar) = 'shs'
            vardesc(nvar) = 'specific humidity (snow)'
            varunit(nvar) = 'g/g'
          endif
          if( qname(n).eq.'qg ' )then
            do2 = .true.
            nvar = nvar+1
            varname(nvar) = 'shg'
            vardesc(nvar) = 'specific humidity (graupel)'
            varunit(nvar) = 'g/g'
          endif

          IF( do2 )THEN

            do k=1,nk
            do j=1,nj
            do i=1,ni
              dum1(i,j,k) = q3d(i,j,k,n)/(1.0+q3d(i,j,k,n))
            enddo
            enddo
            enddo

            call getavg3d(dum1,savg)
            call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

          ENDIF

        ENDDO

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'qliq'
        vardesc(nvar) = 'liquid water mixing ratio'
        varunit(nvar) = 'g/g'
        call getavg3d(ql,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save qlavg:
        do k=1,nk
          qlavg(k) = savg(k)
        enddo

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'qice'
        vardesc(nvar) = 'ice mixing ratio (qs+qg+qi)'
        varunit(nvar) = 'g/g'
        call getavg3d(qice,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'qt'
        vardesc(nvar) = 'total water mixing ratio'
        varunit(nvar) = 'g/g'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = q3d(i,j,k,nqv)+ql(i,j,k)+qice(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save qtavg:
        do k=1,nk
          qtavg(k) = savg(k)
        enddo

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 .and. output_dbz.eq.1 .and. qd_dbz.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'dbz'
        vardesc(nvar) = 'reflectivity'
        varunit(nvar) = 'dBZ'
        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_dbz),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 .and. ptype.eq.5 .and. getvt )THEN

        nvar = nvar+1
        varname(nvar) = 'fc'
        vardesc(nvar) = 'fall velocity of qc'
        varunit(nvar) = 'm/s'
        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_vtc),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'fr'
        vardesc(nvar) = 'fall velocity of qr'
        varunit(nvar) = 'm/s'
        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_vtr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'fi'
        vardesc(nvar) = 'fall velocity of qi'
        varunit(nvar) = 'm/s'
        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_vti),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'fs'
        vardesc(nvar) = 'fall velocity of qs'
        varunit(nvar) = 'm/s'
        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_vts),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'fg'
        vardesc(nvar) = 'fall velocity of qg'
        varunit(nvar) = 'm/s'
        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_vtg),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 .and. ptype.eq.5 .and. getvt )THEN

        dum2 = 0.0

        nvar = nvar+1
        varname(nvar) = 'precc'
        vardesc(nvar) = 'precip flux for qc'
        varunit(nvar) = 'kg m-2 s-1'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = rho(i,j,k)*qdiag(i,j,k,qd_vtc)*q3d(i,j,k,nqc)
          dum2(i,j,k) = dum2(i,j,k)+dum1(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'precr'
        vardesc(nvar) = 'precip flux for qr'
        varunit(nvar) = 'kg m-2 s-1'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = rho(i,j,k)*qdiag(i,j,k,qd_vtr)*q3d(i,j,k,nqr)
          dum2(i,j,k) = dum2(i,j,k)+dum1(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'preci'
        vardesc(nvar) = 'precip flux for qi'
        varunit(nvar) = 'kg m-2 s-1'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = rho(i,j,k)*qdiag(i,j,k,qd_vti)*q3d(i,j,k,nqi)
          dum2(i,j,k) = dum2(i,j,k)+dum1(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'precs'
        vardesc(nvar) = 'precip flux for qs'
        varunit(nvar) = 'kg m-2 s-1'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = rho(i,j,k)*qdiag(i,j,k,qd_vts)*q3d(i,j,k,nqs)
          dum2(i,j,k) = dum2(i,j,k)+dum1(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'precg'
        vardesc(nvar) = 'precip flux for qg'
        varunit(nvar) = 'kg m-2 s-1'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = rho(i,j,k)*qdiag(i,j,k,qd_vtg)*q3d(i,j,k,nqg)
          dum2(i,j,k) = dum2(i,j,k)+dum1(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'prec'
        vardesc(nvar) = 'total precip flux'
        varunit(nvar) = 'kg m-2 s-1'
        call getavg3d(dum2,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN
      ! fraction of cloudy/rainy grid points:

!!!        nvar = nvar+1
!!!        varname(nvar) = 'qcrit'
!!!        vardesc(nvar) = 'qcrit'
!!!        varunit(nvar) = 'kg/kg'
!!!        do k=1,nk
!!!          savg(k) = qcrit(k)
!!!        enddo
!!!        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      dum1 = 0.0
      dum2 = 0.0
      dum3 = 0.0
      dum4 = 0.0
      dum5 = 0.0

      do k=1,nk
        if( nqc.ge.1 )then
          do j=1,nj
          do i=1,ni
            if( q3d(i,j,k,nqc).ge.qcrit(k) ) dum1(i,j,k) = dum1(i,j,k)+1.0
          enddo
          enddo
        endif
        if( nqr.ge.1 )then
          do j=1,nj
          do i=1,ni
            if( q3d(i,j,k,nqr).ge.qcrit(k) ) dum2(i,j,k) = dum2(i,j,k)+1.0
          enddo
          enddo
        endif
        do j=1,nj
        do i=1,ni
          if( ql(i,j,k).ge.qcrit(k) ) dum3(i,j,k) = dum3(i,j,k)+1.0
        enddo
        enddo
        do j=1,nj
        do i=1,ni
          if( qice(i,j,k).ge.qcrit(k) ) dum4(i,j,k) = dum4(i,j,k)+1.0
        enddo
        enddo
        do j=1,nj
        do i=1,ni
          if( (ql(i,j,k)+qice(i,j,k)).ge.qcrit(k) ) dum5(i,j,k) = dum5(i,j,k)+1.0
        enddo
        enddo
      enddo

        nvar = nvar+1
        varname(nvar) = 'qcfrac'
        vardesc(nvar) = 'cloud water fraction'
        varunit(nvar) = 'dimensionless'
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'qrfrac'
        vardesc(nvar) = 'rain water fraction'
        varunit(nvar) = 'dimensionless'
        call getavg3d(dum2,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'qlfrac'
        vardesc(nvar) = 'liquid water fraction (qc+qr)'
        varunit(nvar) = 'dimensionless'
        call getavg3d(dum3,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'qifrac'
        vardesc(nvar) = 'ice water fraction (qs+qg+qi)'
        varunit(nvar) = 'dimensionless'
        call getavg3d(dum4,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'qtfrac'
        vardesc(nvar) = 'total water fraction (qc+qr+qs+qg+qi)'
        varunit(nvar) = 'dimensionless'
        call getavg3d(dum5,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN

      ! mass fractions:

      tmass = 0.0
      clw = 0.0
      cli = 0.0
      plw = 0.0
      pli = 0.0

      DO k=1,nk
        do j=1,nj
        do i=1,ni
          tmass(k) = tmass(k)+rho(i,j,k)*(1.0+q3d(i,j,k,nqv)+ql(i,j,k)+qice(i,j,k))
        enddo
        enddo
        DO n=1,numq
          qflag = 0
          if( qflag.eq.0 .and. cloudvar(n) .and. (n.ge.nql1) .and. (n.le.nql2) )then
            qflag = 1
            do j=1,nj
            do i=1,ni
              clw(k) = clw(k)+rho(i,j,k)*q3d(i,j,k,n)
            enddo
            enddo
          endif
          if( qflag.eq.0 .and. cloudvar(n) .and. (n.ge.nqs1) .and. (n.le.nqs2) )then
            qflag = 1
            do j=1,nj
            do i=1,ni
              cli(k) = cli(k)+rho(i,j,k)*q3d(i,j,k,n)
            enddo
            enddo
          endif
          if( qflag.eq.0 .and. (n.ge.nql1) .and. (n.le.nql2) )then
            qflag = 1
            do j=1,nj
            do i=1,ni
              plw(k) = plw(k)+rho(i,j,k)*q3d(i,j,k,n)
            enddo
            enddo
          endif
          if( qflag.eq.0 .and. (n.ge.nqs1) .and. (n.le.nqs2) )then
            qflag = 1
            do j=1,nj
            do i=1,ni
              pli(k) = pli(k)+rho(i,j,k)*q3d(i,j,k,n)
            enddo
            enddo
          endif
        ENDDO
      ENDDO

      call MPI_ALLREDUCE(MPI_IN_PLACE,tmass(1),nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,clw(1)  ,nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,cli(1)  ,nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,plw(1)  ,nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,pli(1)  ,nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

      do k=1,nk
        clw(k) = clw(k)/tmass(k)
        cli(k) = cli(k)/tmass(k)
        plw(k) = plw(k)/tmass(k)
        pli(k) = pli(k)/tmass(k)
      enddo

      nvar = nvar+1
      varname(nvar) = 'clw'
      vardesc(nvar) = 'mass fraction of cloud liquid water'
      varunit(nvar) = 'kg/kg'
      call write3d(clw,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'cli'
      vardesc(nvar) = 'mass fraction of cloud ice'
      varunit(nvar) = 'kg/kg'
      call write3d(cli,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'plw'
      vardesc(nvar) = 'mass fraction of precipitating liquid water'
      varunit(nvar) = 'kg/kg'
      call write3d(plw,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      nvar = nvar+1
      varname(nvar) = 'pli'
      vardesc(nvar) = 'mass fraction of preciptating ice'
      varunit(nvar) = 'kg/kg'
      call write3d(pli,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'thv'
        vardesc(nvar) = 'virtual potential temperature'
        varunit(nvar) = 'K'

        call getavg3d(thv,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save thvavg:
        do k=1,nk
          thvavg(k) = savg(k)
        enddo

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'thl'
        vardesc(nvar) = 'liquid-water potential temp (simple def.)'
        varunit(nvar) = 'K'

        ! (use simple definition ... for now)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          thl(i,j,k) = th(i,j,k)*( 1.0-xlv*ql(i,j,k)/(cp*th(i,j,k)*(pi0(i,j,k)+pp3d(i,j,k))) )
        enddo
        enddo
        enddo

        call getavg3d(thl,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save thlavg:
        do k=1,nk
          thlavg(k) = savg(k)
        enddo

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'the'
        vardesc(nvar) = 'equivalent potential temperature'
        varunit(nvar) = 'K'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          tx = (th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k))
          qx = q3d(i,j,k,nqv)
          px = prs(i,j,k)
          if(q3d(i,j,k,nqc).ge.clwsat)then
            tlcl=tx
          else
            ee=0.01*px*qx/(eps+qx)
            tlcl=55.0+2840.0/(3.5*alog(tx)-log(1.0e-20+ee)-4.805)
          endif
          dum1(i,j,k) = tx*((p00/px)**(0.2854*(1.0-0.28*qx)))   &
                          *exp(((3376.0/tlcl)-2.54)*qx*(1.0+0.81*qx))
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'rh'
        vardesc(nvar) = 'relative humidity (wrt liquid)'
        varunit(nvar) = 'nondimensional'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = q3d(i,j,k,nqv)/rslf(prs(i,j,k),th(i,j,k)*(pi0(i,j,k)+pp3d(i,j,k)))
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 .and. iice.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'rhi'
        vardesc(nvar) = 'relative humidity (wrt ice)'
        varunit(nvar) = 'nondimensional'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = q3d(i,j,k,nqv)/rsif(prs(i,j,k),th(i,j,k)*(pi0(i,j,k)+pp3d(i,j,k)))
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( sgsmodel.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'stke'
        vardesc(nvar) = 'subgrid turbulence kinetic energy'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = tke3d(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          stke(k) = savg(k)
        enddo

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( cm1setup.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'dissten'
        vardesc(nvar) = 'parameterized dissipation rate'
        varunit(nvar) = 'm2/s3'
        vargrid(nvar) = 'w'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dissten(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( ipbl.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'xkzh'
        vardesc(nvar) = 'eddy diffusivity for heat (from YSU)'
        varunit(nvar) = 'm2/s'
        vargrid(nvar) = 'w'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = xkzh(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'xkzq'
        vardesc(nvar) = 'eddy diffusivity for moisture (from YSU)'
        varunit(nvar) = 'm2/s'
        vargrid(nvar) = 'w'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = xkzq(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'xkzm'
        vardesc(nvar) = 'eddy viscosity (from YSU)'
        varunit(nvar) = 'm2/s'
        vargrid(nvar) = 'w'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = xkzm(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      if( horizturb.eq.1 )then
        nvar = nvar+1
        varname(nvar) = 'kmh'
        vardesc(nvar) = 'eddy viscosity in horiz direction'
        varunit(nvar) = 'm2/s'
        vargrid(nvar) = 'w'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = kmh(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      endif

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( sgsmodel.ge.1 .or. output_nm.eq.1 .or. ipbl.ge.1 )THEN
        nvar = nvar+1
        varname(nvar) = 'nm'
        vardesc(nvar) = 'squared Brunt-Vaisala frequency'
        varunit(nvar) = 's-2'
        vargrid(nvar) = 'w'

        call getavg3d(nm(ib,jb,kb),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( cm1setup.ge.1 .or. output_def.eq.1 .or. ipbl.ge.1 .or. horizturb.eq.1 )THEN
        nvar = nvar+1
        varname(nvar) = 'defh'
        vardesc(nvar) = 'horizontal deformation'
        varunit(nvar) = 's-2'
        vargrid(nvar) = 'w'

        call getavg3d(defh(ib,jb,kb),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'defv'
        vardesc(nvar) = 'vertical deformation'
        varunit(nvar) = 's-2'
        vargrid(nvar) = 'w'

        call getavg3d(defv(ib,jb,kb),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      ENDIF

      !c-c-c-c-c-c-c-c-c-c

    turbcheck:  &
    IF( sgsmodel.ge.1 .or. ipbl.eq.2 )THEN

      if( iusekm.eq.1 )then
        nvar = nvar+1
        varname(nvar) = 'kmh'
        vardesc(nvar) = 'eddy viscosity in horiz direction'
        varunit(nvar) = 'm2/s'
        vargrid(nvar) = 'w'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = kmh(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      endif

      !c-c-c-c-c-c-c-c-c-c

      if( iusekm.eq.1 )then
        nvar = nvar+1
        varname(nvar) = 'kmv'
        vardesc(nvar) = 'eddy viscosity in vert direction'
        varunit(nvar) = 'm2/s'
        vargrid(nvar) = 'w'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = kmv(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      endif

      !c-c-c-c-c-c-c-c-c-c

      if( iusekh.eq.1 )then
        nvar = nvar+1
        varname(nvar) = 'khh'
        vardesc(nvar) = 'eddy diffusivity in horiz direction'
        varunit(nvar) = 'm2/s'
        vargrid(nvar) = 'w'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = khh(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      endif

      !c-c-c-c-c-c-c-c-c-c

      if( iusekh.eq.1 )then
        nvar = nvar+1
        varname(nvar) = 'khv'
        vardesc(nvar) = 'eddy diffusivity in vert direction'
        varunit(nvar) = 'm2/s'
        vargrid(nvar) = 'w'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = khv(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      endif

      !c-c-c-c-c-c-c-c-c-c

      if( iusekh.eq.1 .and. iusekm.eq.1 )then
        nvar = nvar+1
        varname(nvar) = 'pr'
        vardesc(nvar) = 'subgrid Prandtl number'
        varunit(nvar) = 'nondimensional'
        vargrid(nvar) = 'w'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = (1.0e-20+kmv(i,j,k))/(1.0e-20+khv(i,j,k))
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      endif

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'rinum'
        vardesc(nvar) = 'Richardson number in subgrid model'
        varunit(nvar) = 'nondimensional'
        vargrid(nvar) = 'w'

        do j=1,nj
        do i=1,ni
          dum1(i,j,1) = 0.0
          dum1(i,j,nk+1) = 0.0
        enddo
        enddo

        IF(tconfig.eq.1)THEN
          do k=2,nk
          do j=1,nj
          do i=1,ni
            prinv = (1.0e-20+khv(i,j,k))/(1.0e-20+kmv(i,j,k))
            dum1(i,j,k) = nm(i,j,k)*prinv/(1.0e-20+defv(i,j,k)+defh(i,j,k))
          enddo
          enddo
          enddo
        ELSEIF(tconfig.eq.2)THEN
          do k=2,nk
          do j=1,nj
          do i=1,ni
            prinv = (1.0e-20+khv(i,j,k))/(1.0e-20+kmv(i,j,k))
            dum1(i,j,k) = nm(i,j,k)*prinv/(1.0e-20+defv(i,j,k))
          enddo
          enddo
          enddo
        ENDIF

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'grdscl'
        vardesc(nvar) = 'grid scale'
        varunit(nvar) = 'm'
        vargrid(nvar) = 'w'

        dum1 = 0.0

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = ( ((dx*ruh(i))*(dy*rvh(j)))*(dz*rmf(i,j,k)) )**0.33333333
          ! cm1r17:  wall condition near surface
          dum1(i,j,k) = sqrt(1.0/( 1.0/(dum1(i,j,k)**2)                                  &
                                    +1.0/((karman*((zf(i,j,k)-zf(i,j,1))+znt(i,j))*rcs)**2)  &
                                 ) )
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      IF( sgsmodel.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'lenscl'
        vardesc(nvar) = 'turbulence length scale'
        varunit(nvar) = 'm'
        vargrid(nvar) = 'w'

        lenscl = 0.0

        do k=2,nk
        do j=1,nj
        do i=1,ni
          if( tke3d(i,j,k).le.1.0e-10 )then
            ! 170718:
            tk = 1.0e-10
            lenscl(i,j,k) = 0.001*dum1(i,j,k)
          else
            tk=tke3d(i,j,k)
            lenscl(i,j,k)=dum1(i,j,k)
            if(nm(i,j,k).gt.1.0e-6)then
              lenscl(i,j,k)=c_l*sqrt(tk/nm(i,j,k))
              lenscl(i,j,k)=min(lenscl(i,j,k),dum1(i,j,k))
              lenscl(i,j,k)=max(lenscl(i,j,k),0.001*dum1(i,j,k))
            endif
          endif
        enddo
        enddo
        enddo

        call getavg3d(lenscl,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

    ENDIF  turbcheck

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wsp'
        vardesc(nvar) = 'horizontal wind speed (grid-relative)'
        varunit(nvar) = 'm/s'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = sqrt( (0.5*(u3d(i,j,k)+u3d(i+1,j,k)))**2 &
                             +(0.5*(v3d(i,j,k)+v3d(i,j+1,k)))**2 )
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        ! save wsp:
        do k=1,nk
          wsp(k) = savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wspa'
        vardesc(nvar) = 'analytic wind speed (neutral surface layer only)'
        varunit(nvar) = 'm/s'

        do k=1,nk
          savg(k) = (ustbar/karman)*alog( (zh(1,1,k)+zntbar)/zntbar )
          wspa(k) = savg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'sdwsp'
        vardesc(nvar) = 'standard deviation of horizontal wind speed'
        varunit(nvar) = 'm/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = ( sqrt( (0.5*(u3d(i,j,k)+u3d(i+1,j,k)))**2 &
                               +(0.5*(v3d(i,j,k)+v3d(i,j+1,k)))**2 ) - wsp(k) )**2
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

    IF( iptra.eq.1 )THEN

      ptavg = 0.0

      DO n=1,npt

        nvar = nvar+1
        a1 = 'pt                                                                              '
        if(n.le.9)then
          write(a1(3:3),155) n
155       format(i1.1)
        elseif(n.le.99)then
          write(a1(3:4),154) n
154       format(i2.2)
        else
          write(a1(3:5),153) n
153       format(i3.3)
        endif
        varname(nvar) = a1
        vardesc(nvar) = 'passive tracer mixing ratio'
        varunit(nvar) = 'g/g'

        call getavg3d(pt3d(ib,jb,kb,n),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          ptavg(k,n) = savg(k)
        enddo

      ENDDO

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( testcase.eq.4 .or. testcase.eq.5 )THEN

        ! note:  o30 array stores frad

        nvar = nvar+1
        varname(nvar) = 'frad'
        vardesc(nvar) = 'radiative flux'
        varunit(nvar) = 'W/m2'
        call getavg3d(o30(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        ! note:  o30 array stores frad

        nvar = nvar+1
        varname(nvar) = 'thrad'
        vardesc(nvar) = 'pot temp tendency from radiation scheme'
        varunit(nvar) = 'K/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = -(o30(i,j,k+1)-o30(i,j,k))*rdz*mh(i,j,k)  &
                         /(cp*rho0(i,j,k))
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( radopt.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'swten'
        vardesc(nvar) = 'temperature tendency, sw radiation'
        varunit(nvar) = 'K/s'
        call getavg3d(swten(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'lwten'
        vardesc(nvar) = 'temperature tendency, sw radiation'
        varunit(nvar) = 'K/s'
        call getavg3d(lwten(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'swtenc'
        vardesc(nvar) = 'temperature tendency, sw radiation (clear sky)'
        varunit(nvar) = 'K/s'
        call getavg3d(swtenc(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'lwtenc'
        vardesc(nvar) = 'temperature tendency, sw radiation (clear sky)'
        varunit(nvar) = 'K/s'
        call getavg3d(lwtenc(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'cldfra'
        vardesc(nvar) = 'cloud fraction from radiation scheme'
        varunit(nvar) = 'nondimensional'
        call getavg3d(cldfra(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      doit = .true.
      IF( doit )THEN
      IF( radopt.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'effc'
        vardesc(nvar) = 'cloud droplet effective radius'
        varunit(nvar) = 'micron'
        call getavg3d(effc(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'effr'
        vardesc(nvar) = 'rain effective radius'
        varunit(nvar) = 'micron'
        call getavg3d(effr(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'effs'
        vardesc(nvar) = 'snow effective radius'
        varunit(nvar) = 'micron'
        call getavg3d(effs(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'effi'
        vardesc(nvar) = 'cloud ice effective radius'
        varunit(nvar) = 'micron'
        call getavg3d(effi(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'effg'
        vardesc(nvar) = 'graupel/hail effective radius'
        varunit(nvar) = 'micron'
        call getavg3d(effg(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'effis'
        vardesc(nvar) = 'effis'
        varunit(nvar) = 'micron'
        call getavg3d(effis(ibr,jbr,kbr),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF
      ENDIF

      !c-c-c-c-c-c-c-c-c-c

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    ! 1d (z) diagnostics:

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'phim'
        vardesc(nvar) = 'nondimensional wind shear'
        varunit(nvar) = 'nondimensinal'
        vargrid(nvar) = 'w'

        savg = 0.0

        do k=2,nk
!!!          savg(k) = (wsp(k)-wsp(k-1))*rdz*mf(1,1,k)*karman*zf(1,1,k)/ustbar
          ! 180212:
          savg(k) = (wsp(k)-wsp(k-1))/(wspa(k)-wspa(k-1))
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'dtdz'
        vardesc(nvar) = 'vertical gradient of avg theta'
        varunit(nvar) = 'K/m'
        vargrid(nvar) = 'w'

        savg = 0.0

        do k=2,nk
          savg(k) = (thavg(k)-thavg(k-1))*rdz*mf(1,1,k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'dudz'
        vardesc(nvar) = 'vertical gradient of avg u'
        varunit(nvar) = '1/s'
        vargrid(nvar) = 'w'

        savg = 0.0

        do k=2,nk
          savg(k) = (uavg(k)-uavg(k-1))*rdz*mf(1,1,k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'dvdz'
        vardesc(nvar) = 'vertical gradient of avg v'
        varunit(nvar) = '1/s'
        vargrid(nvar) = 'w'

        savg = 0.0

        do k=2,nk
          savg(k) = (vavg(k)-vavg(k-1))*rdz*mf(1,1,k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'dsdz'
        vardesc(nvar) = 'vertical gradient of avg horiz wind speed'
        varunit(nvar) = '1/s'
        vargrid(nvar) = 'w'

        savg = 0.0

        do k=2,nk
          savg(k) = (wsp(k)-wsp(k-1))*rdz*mf(1,1,k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 )THEN
        nvar = nvar+1
        varname(nvar) = 'dqvdz'
        vardesc(nvar) = 'vertical gradient of avg qv'
        varunit(nvar) = 'g/g/m'
        vargrid(nvar) = 'w'

        savg = 0.0

        do k=2,nk
          savg(k) = (qvavg(k)-qvavg(k-1))*rdz*mf(1,1,k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( testcase.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'ug'
        vardesc(nvar) = 'u-component of geostrophic wind'
        varunit(nvar) = 'm/s'
        do k=1,nk
          savg(k) = ug(k)
        enddo
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'vg'
        vardesc(nvar) = 'v-component of geostrophic wind'
        varunit(nvar) = 'm/s'
        do k=1,nk
          savg(k) = vg(k)
        enddo
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'u0'
        vardesc(nvar) = 'base-state u'
        varunit(nvar) = 'm/s'
        do k=1,nk
          savg(k) = u0(1,1,k)
        enddo
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'v0'
        vardesc(nvar) = 'base-state v'
        varunit(nvar) = 'm/s'
        do k=1,nk
          savg(k) = v0(1,1,k)
        enddo
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF


      IF( testcase.eq.6 )THEN

        nvar = nvar+1
        varname(nvar) = 'dvdr'
        vardesc(nvar) = 'radial gradient of V'
        varunit(nvar) = '1/s'
        do k=1,nk
          savg(k) = dvdr(k)
        enddo
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

    
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    ! 3d vars:  2nd-order and 3rd-order calcs AT SCALAR POINTS:
    !                dum4  =  u-prime
    !                dum5  =  v-prime
    !                dum6  =  w-prime

    dum4 = 0.0
    dum5 = 0.0
    dum6 = 0.0

    do k=1,nk
    do j=1,nj
    do i=1,ni
      dum4(i,j,k) = ( u3d(i,j,k)-uavg(k) )
      dum5(i,j,k) = ( v3d(i,j,k)-vavg(k) )
      dum6(i,j,k) = 0.5*( w3d(i,j,k)-wavg(k) + w3d(i,j,k+1)-wavg(k+1) )
    enddo
    enddo
    enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'upup'
        vardesc(nvar) = '< u-prime u-prime >'
        varunit(nvar) = 'm2/s2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum4(i,j,k)*dum4(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'vpvp'
        vardesc(nvar) = '< v-prime v-prime >'
        varunit(nvar) = 'm2/s2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum5(i,j,k)*dum5(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wpwp'
        vardesc(nvar) = '< w-prime w-prime >'
        varunit(nvar) = 'm2/s2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum6(i,j,k)*dum6(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'upvp'
        vardesc(nvar) = '< u-prime v-prime >'
        varunit(nvar) = 'm2/s2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum4(i,j,k)*dum5(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'upwp'
        vardesc(nvar) = '< u-prime w-prime >'
        varunit(nvar) = 'm2/s2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum4(i,j,k)*dum6(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'vpwp'
        vardesc(nvar) = '< v-prime w-prime >'
        varunit(nvar) = 'm2/s2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum5(i,j,k)*dum6(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'thvarr'
        vardesc(nvar) = 'pot temp variance, resolved'
        varunit(nvar) = 'K^2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = (th(i,j,k)-thavg(k))**2
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'thvarr'
        vardesc(nvar) = 'pot temp variance, resolved'
        varunit(nvar) = 'K^2'
        vargrid(nvar) = 'w'

        dum1 = 0.0

        do k=2,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = ( 0.5*( (th(i,j,k  )-thavg(k  ))   &
                               +(th(i,j,k-1)-thavg(k-1)) ) )**2
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      IF( imoist.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'thvvarr'
        vardesc(nvar) = 'resolved virtual pot temp variance'
        varunit(nvar) = 'K^2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = (thv(i,j,k)-thvavg(k))**2
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'thlvarr'
        vardesc(nvar) = 'resolved liquid-water pot temp variance'
        varunit(nvar) = 'K^2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = (thl(i,j,k)-thlavg(k))**2
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'qvvarr'
        vardesc(nvar) = 'resolved qv variance'
        varunit(nvar) = 'g2/g2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = (q3d(i,j,k,nqv)-qvavg(k))**2
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'qlvarr'
        vardesc(nvar) = 'resolved ql variance'
        varunit(nvar) = 'g2/g2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = (ql(i,j,k)-qlavg(k))**2
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'qtvarr'
        vardesc(nvar) = 'resolved qt variance'
        varunit(nvar) = 'g2/g2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = (q3d(i,j,k,nqv)+ql(i,j,k)-qtavg(k))**2
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wpwptp'
        vardesc(nvar) = '< w-prime w-prime theta-prime >'
        varunit(nvar) = 'K m2/s2'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum6(i,j,k)*dum6(i,j,k)*(th(i,j,k)-thavg(k))
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wptptp'
        vardesc(nvar) = '< w-prime theta-prime theta-prime >'
        varunit(nvar) = 'K^2 m/s'
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum6(i,j,k)*(th(i,j,k)-thavg(k))**2
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    ! 3d vars:  2nd-order and 3rd-order calcs AT W POINTS:
    !                dum4  =  u-prime
    !                dum5  =  v-prime
    !                dum6  =  w-prime

    dum1 = 0.0
    dum4 = 0.0
    dum5 = 0.0
    dum6 = 0.0

    do k=2,nk
    do j=1,nj
    do i=1,ni
      dum4(i,j,k) = 0.5*( (u3d(i,j,k  )-uavg(k  )) &
                         +(u3d(i,j,k-1)-uavg(k-1)) )
      dum5(i,j,k) = 0.5*( (v3d(i,j,k  )-vavg(k  )) &
                         +(v3d(i,j,k-1)-vavg(k-1)) )
      dum6(i,j,k) = w3d(i,j,k)-wavg(k)
    enddo
    enddo
    enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'upup'
        vardesc(nvar) = '< u-prime u-prime >'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        do k=2,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum4(i,j,k)*dum4(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=2,nk
          rtke(k) = rtke(k) + 0.5*savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'vpvp'
        vardesc(nvar) = '< v-prime v-prime >'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        do k=2,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum5(i,j,k)*dum5(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=2,nk
          rtke(k) = rtke(k) + 0.5*savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wpwp'
        vardesc(nvar) = '< w-prime w-prime >'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        do k=2,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum6(i,j,k)*dum6(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=2,nk
          rtke(k) = rtke(k) + 0.5*savg(k)
        enddo

        do k=2,nk
          wvar(k) = savg(k)
        enddo

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'upvp'
        vardesc(nvar) = '< u-prime v-prime >'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        do k=2,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum4(i,j,k)*dum5(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'upwp'
        vardesc(nvar) = '< u-prime w-prime >'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        do k=2,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum4(i,j,k)*dum6(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'vpwp'
        vardesc(nvar) = '< v-prime w-prime >'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        do k=2,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum5(i,j,k)*dum6(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wpwpwp'
        vardesc(nvar) = '< w-prime w-prime w-prime >'
        varunit(nvar) = 'm3/s3'
        vargrid(nvar) = 'w'
        do k=2,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum6(i,j,k)**3
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wpupup'
        vardesc(nvar) = '< w-prime u-prime u-prime >'
        varunit(nvar) = 'm3/s3'
        vargrid(nvar) = 'w'
        do k=2,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum6(i,j,k)*dum4(i,j,k)*dum4(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wpvpvp'
        vardesc(nvar) = '< w-prime v-prime v-prime >'
        varunit(nvar) = 'm3/s3'
        vargrid(nvar) = 'w'
        do k=2,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = dum6(i,j,k)*dum5(i,j,k)*dum5(i,j,k)
        enddo
        enddo
        enddo
        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        call     momentum_flux(u3d,v3d,w3d,t13,t23,rf,rf0,c1,c2,dum3,dum4,dum5,ufr,ufs,ufd,vfr,vfs,vfd)

        nvar = nvar+1
        varname(nvar) = 'ufr'
        vardesc(nvar) = 'vertical flux of u, resolved'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        call write3d(ufr,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'ufs'
        vardesc(nvar) = 'vertical flux of u, subgrid'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        call write3d(ufs,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'ufd'
        vardesc(nvar) = 'vertical flux of u, diffusion'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        call write3d(ufd,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'vfr'
        vardesc(nvar) = 'vertical flux of v, resolved'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        call write3d(vfr,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'vfs'
        vardesc(nvar) = 'vertical flux of v, subgrid'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        call write3d(vfs,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'vfd'
        vardesc(nvar) = 'vertical flux of v, diffusion'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'
        call write3d(vfd,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c
        ! theta fluxes:

        do k=1,nk
        do j=0,nj+1
        do i=0,ni+1
!!!          dum2(i,j,k)=th0(i,j,k)+th3d(i,j,k)
          dum2(i,j,k)=(th0(i,j,k)-th0r)+th3d(i,j,k)
        enddo
        enddo
        enddo

        do k=1,nk
          temavg(k) = thavg(k)-th0r
        enddo

        pdef = 0
        pdefweno = 0
        weps = 10.0*epsilon

        call     scalar_flux(weps,c1,c2,mf,rf0,dum1,dum2,dum3,dum4,dum5,w3d,khv,thflux,wavg,temavg,ptfr,ptfs,ptfd,dosfcflx,1,pdef,pdefweno)

        
        nvar = nvar+1
        varname(nvar) = 'thfr'
        vardesc(nvar) = 'vertical flux of theta, resolved'
        varunit(nvar) = 'K m/s'
        vargrid(nvar) = 'w'
        call write3d(ptfr,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'thfs'
        vardesc(nvar) = 'vertical flux of theta, subgrid'
        varunit(nvar) = 'K m/s'
        vargrid(nvar) = 'w'
        call write3d(ptfs,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'thfd'
        vardesc(nvar) = 'vertical flux of theta, diffusion'
        varunit(nvar) = 'K m/s'
        vargrid(nvar) = 'w'
        call write3d(ptfd,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)


      IF( imoist.eq.0 )THEN

        call     getwstar(zf,thv0,rth0s,ptfr,ptfs,ptfd,thfavg,qvfavg,wstar,fbmin,zfbmin)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c
        ! theta variance

      IF( sgsmodel.eq.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'thvars'
        vardesc(nvar) = 'pot temp variance, subgrid'
        varunit(nvar) = 'K^2'
        vargrid(nvar) = 'w'

        dum1 = 0.0

        do k=2,nk
        do j=1,nj
        do i=1,ni
          if( tkea(i,j,k).ge.1.0e-6 )then
            dum1(i,j,k) = 2.0*lenscl(i,j,k)*khv(i,j,k)                        &
                             *( ((th(i,j,k)-th(i,j,k-1))*rdz*mf(i,j,k))**2 )  &
                             /(2.02*sqrt(max(1.0e-6,tkea(i,j,k))))
          endif
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c
        ! thetav fluxes:

      IF( imoist.eq.1 )THEN

        ! surface flux:
        do j=1,nj
        do i=1,ni
          dum6(i,j,1) = (1.0+repsm1*q3d(i,j,1,nqv))*thflux(i,j)  &
                       +repsm1*th(i,j,1)*qvflux(i,j)
        enddo
        enddo

        pdef = 0
        pdefweno = 0
        weps = 10.0*epsilon

        call     scalar_flux(weps,c1,c2,mf,rf0,dum1,thv,dum3,dum4,dum5,w3d,khv,dum6(ib,jb,1),wavg,thvavg,sfr,sfs,sfd,dosfcflx,1,pdef,pdefweno)

        nvar = nvar+1
        varname(nvar) = 'thvfr'
        vardesc(nvar) = 'vertical flux of theta-v, resolved'
        varunit(nvar) = 'K m/s'
        vargrid(nvar) = 'w'
        call write3d(sfr,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'thvfs'
        vardesc(nvar) = 'vertical flux of theta-v, subgrid'
        varunit(nvar) = 'K m/s'
        vargrid(nvar) = 'w'
        call write3d(sfs,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'thvfd'
        vardesc(nvar) = 'vertical flux of theta-v, diffusion'
        varunit(nvar) = 'K m/s'
        vargrid(nvar) = 'w'
        call write3d(sfd,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        call     getwstar(zf,thv0,rth0s,sfr,sfs,sfd,thfavg,qvfavg,wstar,fbmin,zfbmin)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c
        ! thetal fluxes:

      IF( imoist.eq.1 )THEN

        ! surface flux:
        do j=1,nj
        do i=1,ni
          dum6(i,j,1) = thflux(i,j)
        enddo
        enddo

        pdef = 0
        pdefweno = 0
        weps = 10.0*epsilon

        call     scalar_flux(weps,c1,c2,mf,rf0,dum1,thl,dum3,dum4,dum5,w3d,khv,dum6(ib,jb,1),wavg,thlavg,sfr,sfs,sfd,dosfcflx,1,pdef,pdefweno)

        nvar = nvar+1
        varname(nvar) = 'thlfr'
        vardesc(nvar) = 'vertical flux of theta-l, resolved'
        varunit(nvar) = 'K m/s'
        vargrid(nvar) = 'w'
        call write3d(sfr,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'thlfs'
        vardesc(nvar) = 'vertical flux of theta-l, subgrid'
        varunit(nvar) = 'K m/s'
        vargrid(nvar) = 'w'
        call write3d(sfs,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'thlfd'
        vardesc(nvar) = 'vertical flux of theta-l, diffusion'
        varunit(nvar) = 'K m/s'
        vargrid(nvar) = 'w'
        call write3d(sfd,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF


      !c-c-c-c-c-c-c-c-c-c
        ! qv fluxes:

      IF( imoist.eq.1 )THEN

        pdef = 1
        pdefweno = 0
        weps = 0.01*epsilon

        call     scalar_flux(weps,c1,c2,mf,rf0,dum1,q3d(ib,jb,kb,nqv),dum3,dum4,dum5,w3d,khv,qvflux,wavg,qvavg,qvfr,qvfs,qvfd,dosfcflx,1,pdef,pdefweno)

        nvar = nvar+1
        varname(nvar) = 'qvfr'
        vardesc(nvar) = 'vertical flux of qv, resolved'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(qvfr,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'qvfs'
        vardesc(nvar) = 'vertical flux of qv, subgrid'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(qvfs,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'qvfd'
        vardesc(nvar) = 'vertical flux of qv, diffusion'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(qvfd,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c
        ! ql fluxes:

      IF( imoist.eq.1 )THEN

        do j=1,nj
        do i=1,ni
          dum6(i,j,1) = 0.0
        enddo
        enddo

        pdef = 1
        pdefweno = 1
        weps = 0.01*epsilon

        call     scalar_flux(weps,c1,c2,mf,rf0,dum1,ql,dum3,dum4,dum5,w3d,khv,dum6(ib,jb,1),wavg,qlavg,sfr,sfs,sfd,dosfcflx,0,pdef,pdefweno)

        nvar = nvar+1
        varname(nvar) = 'qlfr'
        vardesc(nvar) = 'vertical flux of ql, resolved'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(sfr,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'qlfs'
        vardesc(nvar) = 'vertical flux of ql, subgrid'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(sfs,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'qlfd'
        vardesc(nvar) = 'vertical flux of ql, diffusion'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(sfd,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c
        ! qt fluxes:

      IF( imoist.eq.1 )THEN

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum2(i,j,k) = q3d(i,j,k,nqv)+ql(i,j,k)
        enddo
        enddo
        enddo

        pdef = 1
        pdefweno = 1
        weps = 0.01*epsilon

        call     scalar_flux(weps,c1,c2,mf,rf0,dum1,dum2,dum3,dum4,dum5,w3d,khv,qvflux,wavg,qtavg,sfr,sfs,sfd,dosfcflx,1,pdef,pdefweno)

        nvar = nvar+1
        varname(nvar) = 'qtfr'
        vardesc(nvar) = 'vertical flux of qt, resolved'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(sfr,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'qtfs'
        vardesc(nvar) = 'vertical flux of qt, subgrid'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(sfs,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar = nvar+1
        varname(nvar) = 'qtfd'
        vardesc(nvar) = 'vertical flux of qt, diffusion'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(sfd,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c
        ! pt fluxes:

      IF( iptra.eq.1 )THEN
      DO n=1,npt

        if( pdtra.eq.1 )then
          pdef = 1
        else
          pdef = 0
        endif
        pdefweno = 1
        weps = 1.0*epsilon

        do j=1,nj
        do i=1,ni
          dum6(i,j,1) = 0.0
        enddo
        enddo

        call     scalar_flux(weps,c1,c2,mf,rf0,dum1,pt3d(ib,jb,kb,n),dum3,dum4,dum5,w3d,khv,dum6(ib,jb,1),wavg,ptavg(0,n),sfr,sfs,sfd,dosfcflx,1,pdef,pdefweno)

        a1 = 'ptfr                                                                            '
        if(n.le.9)then
          write(a1(5:5),155) n
        elseif(n.le.99)then
          write(a1(5:6),154) n
        else
          write(a1(5:7),153) n
        endif

        nvar = nvar+1
        varname(nvar) = a1
        vardesc(nvar) = 'vertical flux of pt, resolved'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(sfr,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        a1 = 'ptfs                                                                            '
        if(n.le.9)then
          write(a1(5:5),155) n
        elseif(n.le.99)then
          write(a1(5:6),154) n
        else
          write(a1(5:7),153) n
        endif

        nvar = nvar+1
        varname(nvar) = a1
        vardesc(nvar) = 'vertical flux of pt, subgrid'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(sfs,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        a1 = 'ptfd                                                                            '
        if(n.le.9)then
          write(a1(5:5),155) n
        elseif(n.le.99)then
          write(a1(5:6),154) n
        else
          write(a1(5:7),153) n
        endif

        nvar = nvar+1
        varname(nvar) = a1
        vardesc(nvar) = 'vertical flux of pt, diffusion'
        varunit(nvar) = 'g/g m/s'
        vargrid(nvar) = 'w'
        call write3d(sfd,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDDO
      ENDIF
      !c-c-c-c-c-c-c-c-c-c

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    ! subgrid TKE budget:

    IF( sgsmodel.eq.1 )THEN
      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'stkeb_shear'
        vardesc(nvar) = 'subgrid tke budget: shear term'
        varunit(nvar) = 'm2/s3'
        vargrid(nvar) = 'w'

          do j=1,nj
          do i=1,ni
            dum1(i,j,1) = ust(i,j)*ust(i,j)*ust(i,j)/(karman*znt(i,j))
          enddo
          enddo

          do k=2,nk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = kmv(i,j,k)*max(0.0,(defv(i,j,k)+defh(i,j,k)))
          enddo
          enddo
          enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'stkeb_buoy'
        vardesc(nvar) = 'subgrid tke budget: buoyancy term'
        varunit(nvar) = 'm2/s3'
        vargrid(nvar) = 'w'

          do j=1,nj
          do i=1,ni
            dum1(i,j,1) = g*( thflux(i,j)*rth0s(i,j) + repsm1*qvflux(i,j) )
          enddo
          enddo

          do k=2,nk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = -khv(i,j,k)*nm(i,j,k)
          enddo
          enddo
          enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'stkeb_diss'
        vardesc(nvar) = 'subgrid tke budget: dissipation term'
        varunit(nvar) = 'm2/s3'
        vargrid(nvar) = 'w'

          do j=1,nj
          do i=1,ni
!!!            dum1(i,j,1) = -ust(i,j)*ust(i,j)*ust(i,j)/(karman*znt(i,j))  &
!!!                          -g*( thflux(i,j)*rth0s(i,j) + repsm1*qvflux(i,j) )
            dum1(i,j,1) = 0.0
            dum1(i,j,nk+1) = 0.0
          enddo
          enddo

          do k=2,nk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = -dissten(i,j,k)
          enddo
          enddo
          enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'stkeb_adv'
        vardesc(nvar) = 'subgrid tke budget: advection term'
        varunit(nvar) = 'm2/s3'
        vargrid(nvar) = 'w'

          do k=1,nk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = kdiag(i,j,k,kd_adv)
          enddo
          enddo
          enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'stkeb_diff'
        vardesc(nvar) = 'subgrid tke budget: diffusion term'
        varunit(nvar) = 'm2/s3'
        vargrid(nvar) = 'w'

          do k=1,nk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = kdiag(i,j,k,kd_turb)
          enddo
          enddo
          enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'stkef'
        vardesc(nvar) = 'param. vert flux of subgrid tke'
        varunit(nvar) = 'm3/s3'

        dum1 = 0.0

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = -0.5*(kmv(i,j,k)+kmv(i,j,k+1))*(tke3d(i,j,k+1)-tke3d(i,j,k))*rdz*mh(i,j,k)*rho(i,j,k)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

    ENDIF

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !  theta tendencies:

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'ptb_vturbr'
        vardesc(nvar) = 'theta budget: vertical turbulence (resolved)'
        varunit(nvar) = 'K/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*ptfr(k+1)-rfavg(k)*ptfr(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'ptb_vturbs'
        vardesc(nvar) = 'theta budget: vertical turbulence (subgrid)'
        varunit(nvar) = 'K/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*ptfs(k+1)-rfavg(k)*ptfs(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'ptb_vturbd'
        vardesc(nvar) = 'theta budget: vertical implicit diffusion'
        varunit(nvar) = 'K/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*ptfd(k+1)-rfavg(k)*ptfd(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      if( td_hadv.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_hadv'
      if( hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 )then
        vardesc(nvar) = 'theta budget: horizontal advection (non-diff component)'
      else
        vardesc(nvar) = 'theta budget: horizontal advection'
      endif
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_hadv),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_vadv.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_vadv'
      if( vadvordrs.eq.3 .or. vadvordrs.eq.5 .or. vadvordrs.eq.7 .or. vadvordrs.eq.9 .or. advwenos.ge.1 )then
        vardesc(nvar) = 'theta budget: vertical advection (non-diff component)'
      else
        vardesc(nvar) = 'theta budget: vertical advection'
      endif
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_vadv),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_hidiff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_hidiff'
        vardesc(nvar) = 'theta budget: horiz implicit diffusion'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_hidiff),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_vidiff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_vidiff'
        vardesc(nvar) = 'theta budget: vert implicit diffusion'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_vidiff),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_hediff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_hediff'
        vardesc(nvar) = 'theta budget: horiz explicit diffusion'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_hediff),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_vediff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_vediff'
        vardesc(nvar) = 'theta budget: vertical explicit diffusion'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_vediff),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_hturb.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_hturb'
        vardesc(nvar) = 'theta budget: horizontal parameterized turbulence'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_hturb),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_vturb.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_vturb'
        vardesc(nvar) = 'theta budget: vert parameterized turbulence'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_vturb),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_mp.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_mp'
        vardesc(nvar) = 'theta budget: microphysics'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_mp),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_rdamp.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_rdamp'
        vardesc(nvar) = 'theta budget: Rayleigh damper'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_rdamp),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_rad.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_rad'
        vardesc(nvar) = 'theta budget: radiation scheme'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_rad),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_div.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_div'
        vardesc(nvar) = 'theta budget: moist divergence term'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_div),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_diss.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_diss'
        vardesc(nvar) = 'theta budget: dissipative heating'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_diss),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_pbl.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_pbl'
        vardesc(nvar) = 'theta budget: PBL scheme'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_pbl),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_subs.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ptb_subs'
        vardesc(nvar) = 'theta budget: large-scale subsidence'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_subs),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_cond.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'tt_cond'
        vardesc(nvar) = 'theta tendency: condensation'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_cond),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_evac.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'tt_evac'
        vardesc(nvar) = 'theta tendency: cloudwater evaporation'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_evac),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_evar.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'tt_evar'
        vardesc(nvar) = 'theta budget: rainwater evaporation'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_evar),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_dep.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'tt_dep'
        vardesc(nvar) = 'theta tendency: deposition'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_dep),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_subl.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'tt_subl'
        vardesc(nvar) = 'theta tendency: sublimation'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_subl),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_melt.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'tt_melt'
        vardesc(nvar) = 'theta tendency: melting'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_melt),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_frz.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'tt_frz'
        vardesc(nvar) = 'theta tendency: freezing'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_frz),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( td_efall.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'td_efall'
        vardesc(nvar) = 'temp. tendency: energy fallout terms'
        varunit(nvar) = 'K/s'

        call getavg3d(tdiag(ibdt,jbdt,kbdt,td_efall),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      IF( testcase.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'ptb_frc'
        vardesc(nvar) = 'theta budget: idealized forcing'
        varunit(nvar) = 'K/s'

        do k=1,nk
          savg(k) = thfrc(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !  qv tendencies:

    imoist1:  &
    IF( imoist.eq.1 )THEN

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'qvb_vturbr'
        vardesc(nvar) = 'qv budget: vertical turbulence (resolved)'
        varunit(nvar) = 'g/g/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*qvfr(k+1)-rfavg(k)*qvfr(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'qvb_vturbs'
        vardesc(nvar) = 'qv budget: vertical turbulence (subgrid)'
        varunit(nvar) = 'g/g/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*qvfs(k+1)-rfavg(k)*qvfs(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'qvb_vturbd'
        vardesc(nvar) = 'qv budget: vertical implicit diffusion'
        varunit(nvar) = 'g/g/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*qvfd(k+1)-rfavg(k)*qvfd(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      if( qd_hadv.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_hadv'
      if( hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 )then
        vardesc(nvar) = 'qv budget: horizontal advection (non-diff component)'
      else
        vardesc(nvar) = 'qv budget: horizontal advection'
      endif
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_hadv),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_vadv.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_vadv'
      if( vadvordrs.eq.3 .or. vadvordrs.eq.5 .or. vadvordrs.eq.7 .or. vadvordrs.eq.9 .or. advwenos.ge.1 )then
        vardesc(nvar) = 'qv budget: vertical advection (non-diff component)'
      else
        vardesc(nvar) = 'qv budget: vertical advection'
      endif
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_vadv),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_hturb.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_hturb'
        vardesc(nvar) = 'qv budget: horizontal parameterized turbulence'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_hturb),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_vturb.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_vturb'
        vardesc(nvar) = 'qv budget: vertical parameterized turbulence'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_vturb),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_mp.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_mp'
        vardesc(nvar) = 'qv budget: microphysics tendency'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_mp),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_pbl.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_pbl'
        vardesc(nvar) = 'qv budget: PBL scheme'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_pbl),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_subs.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_subs'
        vardesc(nvar) = 'qv budget: subsidence'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_subs),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_cond.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_cond'
        vardesc(nvar) = 'qv tendency: condensation'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_cond),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_evac.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_evac'
        vardesc(nvar) = 'qv tendency: cloudwater evaporation'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_evac),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_evar.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_evar'
        vardesc(nvar) = 'qv tendency: rainwater evaporation'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_evar),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_dep.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_dep'
        vardesc(nvar) = 'qv tendency: deposition'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_dep),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_subl.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_subl'
        vardesc(nvar) = 'qv tendency: sublimation'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_subl),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_hidiff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_hidiff'
        vardesc(nvar) = 'qv budget: horizontal implicit diffusion'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_hidiff),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_vidiff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_vidiff'
        vardesc(nvar) = 'qv budget: vertical implicit diffusion'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdq,jbdq,kbdq,qd_vidiff),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_hediff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_hediff'
        vardesc(nvar) = 'qv budget: horizontal explicit diffusion'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdt,jbdt,kbdt,qd_hediff),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( qd_vediff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'qvb_vediff'
        vardesc(nvar) = 'qv budget: vertical explicit diffusion'
        varunit(nvar) = 'g/g/s'

        call getavg3d(qdiag(ibdt,jbdt,kbdt,qd_vediff),savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      IF( testcase.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'qvb_frc'
        vardesc(nvar) = 'qv budget: idealized forcing'
        varunit(nvar) = 'g/g/s'

        do k=1,nk
          savg(k) = qvfrc(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

    ENDIF  imoist1

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !  u tendencies:

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'ub_vturbr'
        vardesc(nvar) = 'u budget: vertical turbulence (resolved)'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*ufr(k+1)-rfavg(k)*ufr(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'ub_vturbs'
        vardesc(nvar) = 'u budget: vertical turbulence (subgrid)'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*ufs(k+1)-rfavg(k)*ufs(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'ub_vturbd'
        vardesc(nvar) = 'u budget: vertical implicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*ufd(k+1)-rfavg(k)*ufd(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      if( ud_hadv.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_hadv'
      if( hadvordrv.eq.3 .or. hadvordrv.eq.5 .or. hadvordrv.eq.7 .or. hadvordrv.eq.9 .or. advwenov.ge.1 )then
        vardesc(nvar) = 'u budget: horizontal advection (non-diff component)'
      else
        vardesc(nvar) = 'u budget: horizontal advection'
      endif
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_hadv)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          u_hadv(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_vadv.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_vadv'
      if( vadvordrv.eq.3 .or. vadvordrv.eq.5 .or. vadvordrv.eq.7 .or. vadvordrv.eq.9 .or. advwenov.ge.1 )then
        vardesc(nvar) = 'u budget: vertical advection (non-diff component)'
      else
        vardesc(nvar) = 'u budget: vertical advection'
      endif
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_vadv)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          u_vadv(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_hidiff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_hidiff'
        vardesc(nvar) = 'u budget: horizontal implicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_hidiff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_vidiff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_vidiff'
        vardesc(nvar) = 'u budget: vertical implicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_vidiff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_hediff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_hediff'
        vardesc(nvar) = 'u budget: horizontal explicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_hediff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_vediff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_vediff'
        vardesc(nvar) = 'u budget: vertical explicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_vediff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_hturb.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_hturb'
        vardesc(nvar) = 'u budget: horizontal parameterized turbulence'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_hturb)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          u_hturb(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_vturb.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_vturb'
        vardesc(nvar) = 'u budget: vertical parameterized turbulence'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_vturb)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          u_vturb(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_pgrad.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_pgrad'
        vardesc(nvar) = 'u budget: pressure gradient'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_pgrad)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          u_pgrad(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_rdamp.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_rdamp'
        vardesc(nvar) = 'u budget: Rayleigh damping'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_rdamp)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_cor.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_cor'
        vardesc(nvar) = 'u budget: Coriolis term'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_cor)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          u_cor(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_cent.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_cent'
        vardesc(nvar) = 'u budget: centrifugal acceleration'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_cent)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_pbl.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_pbl'
        vardesc(nvar) = 'u budget: PBL scheme'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_pbl)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_subs.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'ub_subs'
        vardesc(nvar) = 'u budget: subsidence term'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = udiag(i,j,k,ud_subs)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          u_subs(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      IF( lspgrad.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'ub_lspg'
        vardesc(nvar) = 'u budget: large-scale pressure gradient'
        varunit(nvar) = 'm/s/s'

        if( lspgrad.eq.1 )then
          do k=1,nk
            savg(k) = -fcor*v0(1,1,k)
          enddo
        elseif( lspgrad.eq.2 )then
          do k=1,nk
            savg(k) = -fcor*vg(k)
          enddo
        elseif( lspgrad.eq.3 )then
          do k=1,nk
            savg(k) = -fcor*v0(1,1,k)-v0(1,1,k)*v0(1,1,k)/hurr_rad
          enddo
        else
          savg = 0.0
        endif

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( testcase.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'ub_frc'
        vardesc(nvar) = 'u budget: idealized forcing'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
          savg(k) = ufrc(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !  v tendencies:

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'vb_vturbr'
        vardesc(nvar) = 'v budget: vertical turbulence (resolved)'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*vfr(k+1)-rfavg(k)*vfr(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'vb_vturbs'
        vardesc(nvar) = 'v budget: vertical turbulence (subgrid)'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*vfs(k+1)-rfavg(k)*vfs(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'vb_vturbd'
        vardesc(nvar) = 'v budget: vertical implicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
          savg(k) = -(rfavg(k+1)*vfd(k+1)-rfavg(k)*vfd(k))*rdz*mh(1,1,k)/rhoavg(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      if( vd_hadv.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_hadv'
      if( hadvordrv.eq.3 .or. hadvordrv.eq.5 .or. hadvordrv.eq.7 .or. hadvordrv.eq.9 .or. advwenov.ge.1 )then
        vardesc(nvar) = 'v budget: horizontal advection (non-diff component)'
      else
        vardesc(nvar) = 'v budget: horizontal advection'
      endif
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_hadv)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          v_hadv(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_vadv.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_vadv'
      if( vadvordrv.eq.3 .or. vadvordrv.eq.5 .or. vadvordrv.eq.7 .or. vadvordrv.eq.9 .or. advwenov.ge.1 )then
        vardesc(nvar) = 'v budget: vertical advection (non-diff component)'
      else
        vardesc(nvar) = 'v budget: vertical advection'
      endif
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_vadv)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          v_vadv(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_hidiff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_hidiff'
        vardesc(nvar) = 'v budget: horizontal implicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_hidiff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_vidiff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_vidiff'
        vardesc(nvar) = 'v budget: vertical implicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_vidiff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_hediff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_hediff'
        vardesc(nvar) = 'v budget: horizontal explicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_hediff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_vediff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_vediff'
        vardesc(nvar) = 'v budget: vertical explicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_vediff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_hturb.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_hturb'
        vardesc(nvar) = 'v budget: horizontal parameterized turbulence'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_hturb)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          v_hturb(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_vturb.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_vturb'
        vardesc(nvar) = 'v budget: vertical parameterized turbulence'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_vturb)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          v_vturb(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_pgrad.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_pgrad'
        vardesc(nvar) = 'v budget: pressure gradient'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_pgrad)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          v_pgrad(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_rdamp.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_rdamp'
        vardesc(nvar) = 'v budget: Rayleigh damping'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_rdamp)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_cor.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_cor'
        vardesc(nvar) = 'v budget: Coriolis term'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_cor)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          v_cor(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_cent.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_cent'
        vardesc(nvar) = 'v budget: centrifugal acceleration'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_cent)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_pbl.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_pbl'
        vardesc(nvar) = 'v budget: PBL scheme'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_pbl)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( vd_subs.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'vb_subs'
        vardesc(nvar) = 'v budget: subsidence term'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = vdiag(i,j,k,vd_subs)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          v_subs(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      IF( lspgrad.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'vb_lspg'
        vardesc(nvar) = 'v budget: large-scale pressure gradient'
        varunit(nvar) = 'm/s/s'

        if( lspgrad.eq.1 )then
          do k=1,nk
            savg(k) = +fcor*u0(1,1,k)
          enddo
        elseif( lspgrad.eq.2 )then
          do k=1,nk
            savg(k) = +fcor*ug(k)
          enddo
        else
          savg = 0.0
        endif

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

      IF( testcase.ge.1 )THEN

        nvar = nvar+1
        varname(nvar) = 'vb_frc'
        vardesc(nvar) = 'v budget: idealized forcing'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
          savg(k) = vfrc(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !  w tendencies:

      !c-c-c-c-c-c-c-c-c-c

      if( wd_hadv.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'wb_hadv'
      if( hadvordrv.eq.3 .or. hadvordrv.eq.5 .or. hadvordrv.eq.7 .or. hadvordrv.eq.9 .or. advwenov.ge.1 )then
        vardesc(nvar) = 'w budget: horizontal advection (non-diff component)'
      else
        vardesc(nvar) = 'w budget: horizontal advection'
      endif
        varunit(nvar) = 'm/s/s'
        vargrid(nvar) = 'w'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = wdiag(i,j,k,wd_hadv)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          w_hadv(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( wd_vadv.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'wb_vadv'
      if( vadvordrv.eq.3 .or. vadvordrv.eq.5 .or. vadvordrv.eq.7 .or. vadvordrv.eq.9 .or. advwenov.ge.1 )then
        vardesc(nvar) = 'w budget: vertical advection (non-diff component)'
      else
        vardesc(nvar) = 'w budget: vertical advection'
      endif
        varunit(nvar) = 'm/s/s'
        vargrid(nvar) = 'w'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = wdiag(i,j,k,wd_vadv)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          w_vadv(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( wd_hturb.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'wb_hturb'
        vardesc(nvar) = 'w budget: horizontal parameterized turbulence'
        varunit(nvar) = 'm/s/s'
        vargrid(nvar) = 'w'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = wdiag(i,j,k,wd_hturb)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          w_hturb(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( wd_vturb.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'wb_vturb'
        vardesc(nvar) = 'w budget: vertical parameterized turbulence'
        varunit(nvar) = 'm/s/s'
        vargrid(nvar) = 'w'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = wdiag(i,j,k,wd_vturb)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=1,nk
          w_vturb(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( wd_pgrad.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'wb_pgrad'
        vardesc(nvar) = 'w budget: pressure gradient'
        varunit(nvar) = 'm/s/s'
        vargrid(nvar) = 'w'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = wdiag(i,j,k,wd_pgrad)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=2,nk
          w_pgrad(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( wd_rdamp.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'wb_rdamp'
        vardesc(nvar) = 'w budget: Rayleigh damping'
        varunit(nvar) = 'm/s/s'
        vargrid(nvar) = 'w'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = wdiag(i,j,k,wd_rdamp)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( wd_buoy.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'wb_buoy'
        vardesc(nvar) = 'w budget: buoyancy'
        varunit(nvar) = 'm/s/s'
        vargrid(nvar) = 'w'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = wdiag(i,j,k,wd_buoy)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        do k=2,nk
          w_buoy(k) = savg(k)
        enddo

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( wd_hidiff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'wb_hidiff'
        vardesc(nvar) = 'w budget: horizontal implicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = wdiag(i,j,k,wd_hidiff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( wd_vidiff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'wb_vidiff'
        vardesc(nvar) = 'w budget: vertical implicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = wdiag(i,j,k,wd_vidiff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( wd_hediff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'wb_hediff'
        vardesc(nvar) = 'w budget: horizontal explicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = wdiag(i,j,k,wd_hediff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( wd_vediff.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'wb_vediff'
        vardesc(nvar) = 'w budget: vertical explicit diffusion'
        varunit(nvar) = 'm/s/s'

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = wdiag(i,j,k,wd_vediff)
        enddo
        enddo
        enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !  resolved tke tendencies:

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'rtke'
        vardesc(nvar) = 'resolved tke'
        varunit(nvar) = 'm2/s2'
        vargrid(nvar) = 'w'

        do k=1,nk
          savg(k) = rtke(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      ! dum4  =  u-prime
      ! dum5  =  v-prime
      ! dum6  =  w-prime

      dum4 = 0.0
      dum5 = 0.0
      dum6 = 0.0

      do k=1,nk
      do j=1,nj+1
      do i=1,ni+1
        ! cm1r19.6 bug fix:
        dum4(i,j,k) = u3d(i,j,k)-uavg(k)
        dum5(i,j,k) = v3d(i,j,k)-vavg(k)
        dum6(i,j,k) = w3d(i,j,k)-wavg(k)
      enddo
      enddo
      enddo

      !c-c-c-c-c-c-c-c-c-c

      if( wd_buoy.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'rtkeb_buoy'
        vardesc(nvar) = 'resolved tke budget: buoyancy term'
        varunit(nvar) = 'm2/s3'
        vargrid(nvar) = 'w'

          do j=1,nj
          do i=1,ni
            dum1(i,j,1) = 0.0
          enddo
          enddo

          do k=2,nk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = ( dum6(i,j,k)*(wdiag(i,j,k,wd_buoy)-w_buoy(k)) )
          enddo
          enddo
          enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_pgrad.ge.1 .and. vd_pgrad.ge.1 .and. wd_pgrad.ge.1)then

        nvar = nvar+1
        varname(nvar) = 'rtkeb_pgrad'
        vardesc(nvar) = 'resolved tke budget: pressure term'
        varunit(nvar) = 'm2/s3'
        vargrid(nvar) = 'w'

          do j=1,nj
          do i=1,ni
            dum1(i,j,1) = 0.0
          enddo
          enddo

          do k=2,nk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) =                                                        &
             +0.25*( dum4(i  ,j,k  )*(udiag(i  ,j,k  ,ud_pgrad)-u_pgrad(k  ))    &
                    +dum4(i+1,j,k  )*(udiag(i+1,j,k  ,ud_pgrad)-u_pgrad(k  ))    &
                    +dum4(i  ,j,k-1)*(udiag(i  ,j,k-1,ud_pgrad)-u_pgrad(k-1))    &
                    +dum4(i+1,j,k-1)*(udiag(i+1,j,k-1,ud_pgrad)-u_pgrad(k-1)) )  &
             +0.25*( dum5(i,j  ,k  )*(vdiag(i,j  ,k  ,vd_pgrad)-v_pgrad(k  ))    &
                    +dum5(i,j+1,k  )*(vdiag(i,j+1,k  ,vd_pgrad)-v_pgrad(k  ))    &
                    +dum5(i,j  ,k-1)*(vdiag(i,j  ,k-1,vd_pgrad)-v_pgrad(k-1))    &
                    +dum5(i,j+1,k-1)*(vdiag(i,j+1,k-1,vd_pgrad)-v_pgrad(k-1)) )  &
                  +( dum6(i,j,k)*(wdiag(i,j,k,wd_pgrad)-w_pgrad(k)) )
          enddo
          enddo
          enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_hadv.ge.1 .and. vd_hadv.ge.1 .and. wd_hadv.ge.1 .and.  &
          ud_vadv.ge.1 .and. vd_vadv.ge.1 .and. wd_vadv.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'rtkeb_adv'
        vardesc(nvar) = 'resolved tke budget: advection term'
        varunit(nvar) = 'm2/s3'
        vargrid(nvar) = 'w'

          do j=1,nj
          do i=1,ni
            dum1(i,j,1) = 0.0
          enddo
          enddo

          do k=2,nk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) =                                                                                           &
             +0.25*( dum4(i  ,j,k  )*(udiag(i  ,j,k  ,ud_hadv)+udiag(i  ,j,k  ,ud_vadv)-u_hadv(k  )-u_vadv(k  ))    &
                    +dum4(i+1,j,k  )*(udiag(i+1,j,k  ,ud_hadv)+udiag(i+1,j,k  ,ud_vadv)-u_hadv(k  )-u_vadv(k  ))    &
                    +dum4(i  ,j,k-1)*(udiag(i  ,j,k-1,ud_hadv)+udiag(i  ,j,k-1,ud_vadv)-u_hadv(k-1)-u_vadv(k-1))    &
                    +dum4(i+1,j,k-1)*(udiag(i+1,j,k-1,ud_hadv)+udiag(i+1,j,k-1,ud_vadv)-u_hadv(k-1)-u_vadv(k-1)) )  &
             +0.25*( dum5(i,j  ,k  )*(vdiag(i,j  ,k  ,vd_hadv)+vdiag(i,j  ,k  ,vd_vadv)-v_hadv(k  )-v_vadv(k  ))    &
                    +dum5(i,j+1,k  )*(vdiag(i,j+1,k  ,vd_hadv)+vdiag(i,j+1,k  ,vd_vadv)-v_hadv(k  )-v_vadv(k  ))    &
                    +dum5(i,j  ,k-1)*(vdiag(i,j  ,k-1,vd_hadv)+vdiag(i,j  ,k-1,vd_vadv)-v_hadv(k-1)-v_vadv(k-1))    &
                    +dum5(i,j+1,k-1)*(vdiag(i,j+1,k-1,vd_hadv)+vdiag(i,j+1,k-1,vd_vadv)-v_hadv(k-1)-v_vadv(k-1)) )  &
                  +( dum6(i,j,k)*(wdiag(i,j,k,wd_hadv)+wdiag(i,j,k,wd_vadv)-w_hadv(k)-w_vadv(k)) )
          enddo
          enddo
          enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c

      if( ud_hturb.ge.1 .and. vd_hturb.ge.1 .and. wd_hturb.ge.1 .and.  &
          ud_vturb.ge.1 .and. vd_vturb.ge.1 .and. wd_vturb.ge.1 )then

        nvar = nvar+1
        varname(nvar) = 'rtkeb_turb'
        vardesc(nvar) = 'resolved tke budget: subgrid turbulence'
        varunit(nvar) = 'm2/s3'
        vargrid(nvar) = 'w'

          do j=1,nj
          do i=1,ni
            dum1(i,j,1) = 0.0
          enddo
          enddo

          do k=2,nk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) =                                                                                               &
             +0.25*( dum4(i  ,j,k  )*(udiag(i  ,j,k  ,ud_hturb)+udiag(i  ,j,k  ,ud_vturb)-u_hturb(k  )-u_vturb(k  ))    &
                    +dum4(i+1,j,k  )*(udiag(i+1,j,k  ,ud_hturb)+udiag(i+1,j,k  ,ud_vturb)-u_hturb(k  )-u_vturb(k  ))    &
                    +dum4(i  ,j,k-1)*(udiag(i  ,j,k-1,ud_hturb)+udiag(i  ,j,k-1,ud_vturb)-u_hturb(k-1)-u_vturb(k-1))    &
                    +dum4(i+1,j,k-1)*(udiag(i+1,j,k-1,ud_hturb)+udiag(i+1,j,k-1,ud_vturb)-u_hturb(k-1)-u_vturb(k-1)) )  &
             +0.25*( dum5(i,j  ,k  )*(vdiag(i,j  ,k  ,vd_hturb)+vdiag(i,j  ,k  ,vd_vturb)-v_hturb(k  )-v_vturb(k  ))    &
                    +dum5(i,j+1,k  )*(vdiag(i,j+1,k  ,vd_hturb)+vdiag(i,j+1,k  ,vd_vturb)-v_hturb(k  )-v_vturb(k  ))    &
                    +dum5(i,j  ,k-1)*(vdiag(i,j  ,k-1,vd_hturb)+vdiag(i,j  ,k-1,vd_vturb)-v_hturb(k-1)-v_vturb(k-1))    &
                    +dum5(i,j+1,k-1)*(vdiag(i,j+1,k-1,vd_hturb)+vdiag(i,j+1,k-1,vd_vturb)-v_hturb(k-1)-v_vturb(k-1)) )  &
                  +( dum6(i,j,k)*(wdiag(i,j,k,wd_hturb)+wdiag(i,j,k,wd_vturb)-w_hturb(k)-w_vturb(k)) )
          enddo
          enddo
          enddo

        call getavg3d(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      endif

      !c-c-c-c-c-c-c-c-c-c


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      !c-c-c-c-c-c-c-c-c-c

!!!      IF( dosub )THEN

        nvar = nvar+1
        varname(nvar) = 'wprof'
        vardesc(nvar) = 'large-scale vertical velocity profile'
        varunit(nvar) = 'm/s'
        vargrid(nvar) = 'w'

        do k=1,nk
          savg(k) = wprof(k)
        enddo

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

!!!      ENDIF

      !c-c-c-c-c-c-c-c-c-c

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wmax'
        vardesc(nvar) = 'maximum w'
        varunit(nvar) = 'm/s'
        vargrid(nvar) = 'w'

        call getmax(w3d(ib,jb,kb),savg,nk+1)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wmin'
        vardesc(nvar) = 'minimum w'
        varunit(nvar) = 'm/s'
        vargrid(nvar) = 'w'

        call getmin(w3d(ib,jb,kb),savg,nk+1)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'tmfu'
        vardesc(nvar) = 'total upward max flux'
        varunit(nvar) = 'kg m/s'
        vargrid(nvar) = 's'

        do k=1,nk
          savg(k)=0.0d0
          do j=1,nj
          do i=1,ni
            savg(k)=savg(k)+rho(i,j,k)*0.5*max(0.0,(w3d(i,j,k)+w3d(i,j,k+1)))*ruh(i)*rvh(j)
          enddo
          enddo
          savg(k)=savg(k)*dx*dy
        enddo

        call MPI_ALLREDUCE(MPI_IN_PLACE,savg(1),nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'tmfd'
        vardesc(nvar) = 'total downward mass flux'
        varunit(nvar) = 'kg m/s'
        vargrid(nvar) = 's'

        do k=1,nk
          savg(k)=0.0d0
          do j=1,nj
          do i=1,ni
            savg(k)=savg(k)+rho(i,j,k)*0.5*min(0.0,(w3d(i,j,k)+w3d(i,j,k+1)))*ruh(i)*rvh(j)
          enddo
          enddo
          savg(k)=savg(k)*dx*dy
        enddo

        call MPI_ALLREDUCE(MPI_IN_PLACE,savg(1),nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum1(i,j,k) = sqrt( (umove+0.5*(u3d(i,j,k)+u3d(i+1,j,k)))**2     &
                             +(vmove+0.5*(v3d(i,j,k)+v3d(i,j+1,k)))**2 )
        enddo
        enddo
        enddo

        nvar = nvar+1
        varname(nvar) = 'wspmax'
        vardesc(nvar) = 'maximum (grnd-rel) horiz wind speed'
        varunit(nvar) = 'm/s'
        vargrid(nvar) = 's'

        call getmax(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'wspmin'
        vardesc(nvar) = 'minimum (grnd-rel) horiz wind speed'
        varunit(nvar) = 'm/s'
        vargrid(nvar) = 's'

        call getmin(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      IF( .not. terrain_flag )THEN

        do k=1,nk
        do j=1,nj+1
        do i=1,ni+1
          dum1(i,j,k) = (v3d(i,j,k)-v3d(i-1,j,k))*rdx*uf(i)   &
                       -(u3d(i,j,k)-u3d(i,j-1,k))*rdy*vf(j)
        enddo
        enddo
        enddo

        nvar = nvar+1
        varname(nvar) = 'zetamax'
        vardesc(nvar) = 'maximum vertical vorticity'
        varunit(nvar) = '1/s'
        vargrid(nvar) = 's'

        call getmax(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar = nvar+1
        varname(nvar) = 'zetamin'
        vardesc(nvar) = 'minimum vertical vorticity'
        varunit(nvar) = '1/s'
        vargrid(nvar) = 's'

        call getmin(dum1,savg)
        call write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      ENDIF

      !c-c-c-c-c-c-c-c-c-c

    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !  more 2d vars

      !c-c-c-c-c-c-c-c-c-c

    IF( sgsmodel.eq.1 )THEN

        ! vertically integrate TKE:

        nvar2d = nvar2d+1
        nvar = nvar+1
        varname(nvar) = 'int_tkes'
        vardesc(nvar) = 'vertically integrated subgrid tke'
        varunit(nvar) = 'kg/s2'
        varlvls(nvar) = 0
        vargrid(nvar) = '2'
        savg2d = 0.0
        do k=2,nk
          savg2d = savg2d+rf0(1,1,k)*stke(k)*dz*rmf(1,1,k)
        enddo
        call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar2d = nvar2d+1
        nvar = nvar+1
        varname(nvar) = 'int_tker'
        vardesc(nvar) = 'vertically integrated resolved tke'
        varunit(nvar) = 'kg/s2'
        varlvls(nvar) = 0
        vargrid(nvar) = '2'
        savg2d = 0.0
        do k=2,nk
          savg2d = savg2d+rf0(1,1,k)*rtke(k)*dz*rmf(1,1,k)
        enddo
        call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

        nvar2d = nvar2d+1
        nvar = nvar+1
        varname(nvar) = 'int_tket'
        vardesc(nvar) = 'vertically integrated total tke'
        varunit(nvar) = 'kg/s2'
        varlvls(nvar) = 0
        vargrid(nvar) = '2'
        savg2d = 0.0
        do k=2,nk
          savg2d = savg2d+rf0(1,1,k)*(stke(k)+rtke(k))*dz*rmf(1,1,k)
        enddo
        call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

        nvar2d = nvar2d+1
        nvar = nvar+1
        varname(nvar) = 'wvar_max'
        vardesc(nvar) = 'maximum vertical velocity variance'
        varunit(nvar) = 'm2/s2'
        varlvls(nvar) = 0
        vargrid(nvar) = '2'

        savg2d = 0.0
        do k=2,nk
          savg2d = max( savg2d , dble(wvar(k)) )
        enddo

        call write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar2d = nvar2d+1
        nvar = nvar+1
        varname(nvar) = 'wstar'
        vardesc(nvar) = 'wstar (vert. integr. buoy flux, r+s)'
        varunit(nvar) = 'm/s'
        varlvls(nvar) = 0
        vargrid(nvar) = '2'

        call write2d(wstar,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar2d = nvar2d+1
        nvar = nvar+1
        varname(nvar) = 'fbmin'
        vardesc(nvar) = 'minimum value of buoyancy flux'
        varunit(nvar) = 'm2/s3'
        varlvls(nvar) = 0
        vargrid(nvar) = '2'

        call write2d(fbmin,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

        nvar2d = nvar2d+1
        nvar = nvar+1
        varname(nvar) = 'zfbmin'
        vardesc(nvar) = 'level of minimum buoyancy flux'
        varunit(nvar) = 'm'
        varlvls(nvar) = 0
        vargrid(nvar) = '2'

        call write2d(zfbmin,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

  !cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc!
  !ccccccc    all done    ccccccccccccccccccccccccccccccccccccccccccccccccccccc!
  !cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc!
  ! close output file:

    id0:  IF( myid.eq.0 )THEN

        ! grads-format
        ! (by default, for now)

        ! close binary output files:
        close(unit=fnums)
        close(unit=fnumw)

      ! write descriptor files:
        do nfile=1,2
          newstring = string
          if( nfile.eq.1 )then
            newstring(totlen+1:totlen+14) = '_turb_s.ctl   '
          elseif( nfile.eq.2 )then
            newstring(totlen+1:totlen+14) = '_turb_w.ctl   '
          endif
          open(unit=66,file=newstring)
          if( nfile.eq.1 )then
            sstring(baselen+1:baselen+1+12) = '_turb_s.dat '
          elseif( nfile.eq.2 )then
            sstring(baselen+1:baselen+1+12) = '_turb_w.dat '
          endif
          write(66,101) sstring
          if( nfile.eq.1 )then
            write(66,103)
          elseif( nfile.eq.2 )then
            write(66,203)
          endif
          write(66,104) grads_undef
          write(66,105)
          write(66,106)
          if( nfile.eq.1 )then
            write(66,107) nk
            do k=1,nk
              write(66,217) 0.001*zh(1,1,k)
            enddo
          elseif( nfile.eq.2 )then
            write(66,107) nk+1
            do k=1,nk+1
              write(66,217) 0.001*zf(1,1,k)
            enddo
          endif
          write(66,108) nwritet
          ntmp = 0
          if( nfile.eq.1 )then
            do n=1,nvar
              if( vargrid(n).eq.'s' .or. vargrid(n).eq.'2' ) ntmp = ntmp+1
            enddo
          else
            do n=1,nvar
              if( vargrid(n).eq.'w' .or. vargrid(n).eq.'2' ) ntmp = ntmp+1
            enddo
          endif
          write(66,109) ntmp
          do n=1,nvar
            doit = .false.
            if( vargrid(n).eq.'2' ) doit = .true.
            if( nfile.eq.1 .and. vargrid(n).eq.'s' ) doit = .true.
            if( nfile.eq.2 .and. vargrid(n).eq.'w' ) doit = .true.
            if( doit )then
              a1 = varname(n)
              a2 = vardesc(n)
              !---
              a16 = '                '
              nn = len(trim(varunit(n)))
              write(a16(2:15),314) varunit(n)
              write(a16(1:1),301 )       '('
              write(a16(nn+2:nn+2),301 ) ')'
              !---
              if(     nfile.eq.1 )then
                write(66,110) a1(1:12),varlvls(n),a2(1:40),a16
              elseif( nfile.eq.2 )then
                if( varlvls(n).eq.0 )then
                  write(66,110) a1(1:12), varlvls(n)   ,a2(1:40),a16
                else
                  write(66,110) a1(1:12),(varlvls(n)+1),a2(1:40),a16
                endif
              endif
            endif
          enddo
          write(66,111)
          close(unit=66)
        enddo

 301    format(a1)
 314    format(a14)

 101    format('dset ^',a70)
 102    format('options template')
 103    format('title CM1 turbulence diagnostics at scalar levels')
 203    format('title CM1 turbulence diagnostics at w levels')
 104    format('undef ',f10.1)
 105    format('xdef 1 linear 0 1')
 106    format('ydef 1 linear 0 1')
 107    format('zdef ',i6,' levels')
 217    format(2x,f13.6)
 108    format('tdef ',i10,' linear 00:00Z03JUL0001 1YR')
 109    format('vars ',i6)
 110    format(a12,2x,i6,' 99 ',a40,1x,a16)
 111    format('endvars')

    ENDIF  id0

    if( myid.eq.0 ) print *,' ..... end turbdiag code ..... '

    end subroutine turbdiag


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine momentum_flux(u3d,v3d,w3d,t13,t23,rf,rf0,c1,c2,dum3,dum4,dum5,ufr,ufs,ufd,vfr,vfs,vfd)
      use input
      use constants
      use interp_routines
      use mpi
      implicit none

      real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: u3d
      real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: v3d
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: w3d
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: t13,t23,rf,rf0,c1,c2
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke)   :: dum3,dum4,dum5
      double precision, intent(inout), dimension(nk+1) :: ufr,ufs,ufd,vfr,vfs,vfd

      integer :: i,j,k
      real :: mfr,mfs,mfd,wbar,wpbar,cc1,cc2
      double precision :: temd,weps
      double precision, dimension(nk) :: ubar,vbar

      weps = 100.0*epsilon

    !-------------------------------------------------------
    !  u component:

      ufr = 0.0
      ufs = 0.0
      ufd = 0.0

      ! baseline algorithm:
      do k=2,nk
      do j=1,nj
      do i=1,ni
        cc2 = 0.5*(c2(i-1,j,k)+c2(i,j,k))
        cc1 = 1.0-cc2
        dum3(i,j,k) = (cc1*u3d(i,j,k-1)+cc2*u3d(i,j,k))
        dum4(i,j,k) = dum3(i,j,k)
      enddo
      enddo
      enddo

    IF( advwenov.ge.1 )THEN

      if(     weno_order.eq.5 )then
        call vinterp_weno5(  2 ,ni+1,nj,nk,c1,c2,w3d,dum3, u3d ,  0 ,0,weps)
        call vinterp_flx6(   2 ,ni+1,nj,nk,c1,c2,w3d,dum4, u3d )
      endif

    ELSE

        !buh3
      if(     vadvordrs.eq.5 )then
        call vinterp_flx5(   2 ,ni+1,nj,nk,c1,c2,w3d,dum3, u3d )
        call vinterp_flx6(   2 ,ni+1,nj,nk,c1,c2,w3d,dum4, u3d )
      elseif( vadvordrs.eq.6 )then
        call vinterp_flx6(   2 ,ni+1,nj,nk,c1,c2,w3d,dum3, u3d )
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum4(i,j,k) = dum3(i,j,k)
        enddo
        enddo
        enddo
      endif

    ENDIF

  !----------------------

    ubar = 0.0

    do k=2,nk
    do j=1,nj
    do i=1,ni
      ubar(k) = ubar(k)+dum3(i,j,k)
    enddo
    enddo
    enddo
        !buh4

    call MPI_ALLREDUCE(MPI_IN_PLACE,ubar(2),(nk-1),MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

    temd = 1.0d0/dble(nx*ny)

    do k=2,nk
      ubar(k)  = ubar(k)*temd
    enddo

  !----------------------

      !$omp parallel do default(shared)   &
      !$omp private(i,j,k,wbar)
      do k=2,nk
        do j=1,nj
        do i=1,ni
          wbar = 0.5*(w3d(i,j,k)+w3d(i-1,j,k))
          ufr(k) = ufr(k) + wbar*(dum4(i,j,k)-ubar(k))
          ufd(k) = ufd(k) + wbar*(dum3(i,j,k)-dum4(i,j,k))
        !buh5
        enddo
        enddo
      enddo

    !-------------------------------------------------------
    !  v component:

      vfr = 0.0
      vfs = 0.0
      vfd = 0.0

      ! baseline algorithm:
      do k=2,nk
      do j=1,nj
      do i=1,ni
        cc2 = 0.5*(c2(i,j-1,k)+c2(i,j,k))
        cc1 = 1.0-cc2
        dum3(i,j,k) = (cc1*v3d(i,j,k-1)+cc2*v3d(i,j,k))
        dum4(i,j,k) = dum3(i,j,k)
      enddo
      enddo
      enddo

    IF( advwenov.ge.1 )THEN

      if(     weno_order.eq.5 )then
        call vinterp_weno5(  3 ,ni,nj+1,nk,c1,c2,w3d,dum3, v3d ,  0 ,0,weps)
        call vinterp_flx6(   3 ,ni,nj+1,nk,c1,c2,w3d,dum4, v3d )
      endif

    ELSE

        !buh3
      if(     vadvordrs.eq.5 )then
        call vinterp_flx5(   3 ,ni,nj+1,nk,c1,c2,w3d,dum3, v3d )
        call vinterp_flx6(   3 ,ni,nj+1,nk,c1,c2,w3d,dum4, v3d )
      elseif( vadvordrs.eq.6 )then
        call vinterp_flx6(   3 ,ni,nj+1,nk,c1,c2,w3d,dum3, v3d )
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum4(i,j,k) = dum3(i,j,k)
        enddo
        enddo
        enddo
      endif

    ENDIF

  !----------------------

    vbar = 0.0

    do k=2,nk
    do j=1,nj
    do i=1,ni
      vbar(k) = vbar(k)+dum3(i,j,k)
    enddo
    enddo
    enddo
        !buh4

    call MPI_ALLREDUCE(MPI_IN_PLACE,vbar(2),(nk-1),MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

    temd = 1.0d0/dble(nx*ny)

    do k=2,nk
      vbar(k)  = vbar(k)*temd
    enddo

  !----------------------

      !$omp parallel do default(shared)   &
      !$omp private(i,j,k,wbar)
      do k=2,nk
        do j=1,nj
        do i=1,ni
          wbar = 0.5*(w3d(i,j,k)+w3d(i,j-1,k))
          vfr(k) = vfr(k) + wbar*(dum4(i,j,k)-vbar(k))
          vfd(k) = vfd(k) + wbar*(dum3(i,j,k)-dum4(i,j,k))
        !buh5
        enddo
        enddo
      enddo

    !-------------------------------------------------------

      if( cm1setup.ge.1 .or. ipbl.eq.2 )then
        !$omp parallel do default(shared)   &
        !$omp private(i,j,k)
        do k=1,nk
          do j=1,nj
          do i=1,ni
            ufs(k) = ufs(k) - t13(i,j,k)/(0.5*(rf(i,j,k)+rf(i-1,j,k)))
            vfs(k) = vfs(k) - t23(i,j,k)/(0.5*(rf(i,j,k)+rf(i,j-1,k)))
          enddo
          enddo
        enddo
      else
        !$omp parallel do default(shared)   &
        !$omp private(i,j,k)
        do k=1,nk
          ufs(k) = 0.0
          vfs(k) = 0.0
        enddo
      endif

    !-------------------------------------------------------

    call MPI_ALLREDUCE(MPI_IN_PLACE,ufr(1) ,nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
    call MPI_ALLREDUCE(MPI_IN_PLACE,ufs(1) ,nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
    call MPI_ALLREDUCE(MPI_IN_PLACE,ufd(1) ,nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

    call MPI_ALLREDUCE(MPI_IN_PLACE,vfr(1) ,nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
    call MPI_ALLREDUCE(MPI_IN_PLACE,vfs(1) ,nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
    call MPI_ALLREDUCE(MPI_IN_PLACE,vfd(1) ,nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

    temd = 1.0d0/dble(nx*ny)
    do k=1,nk
      ufr(k)  = ufr(k)*temd
      ufs(k)  = ufs(k)*temd
      ufd(k)  = ufd(k)*temd

      vfr(k)  = vfr(k)*temd
      vfs(k)  = vfs(k)*temd
      vfd(k)  = vfd(k)*temd
    enddo

      end subroutine momentum_flux


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine scalar_flux(weps,c1,c2,mf,rf0,sp  ,s   ,dum3,dum4,dum5,w3d,khv,sflux ,wavg,savg  ,sfr,sfs,sfd,dosfcflx,iflux,pdef,pdefweno)
      use input
      use constants
      use interp_routines
      use mpi
      implicit none

      double precision, intent(in) :: weps
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: c1,c2,rf0
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: mf
      real, intent(in), dimension(ib:ie,jb:je,kb:ke)   :: sp,s
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke)   :: dum3,dum4,dum5
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: w3d
      real, intent(in), dimension(ibc:iec,jbc:jec,kbc:kec) :: khv
      real, intent(in), dimension(ib:ie,jb:je) :: sflux
      real, intent(in), dimension(0:nk+1) :: wavg,savg
      double precision, intent(inout), dimension(nk+1) :: sfr,sfs,sfd
      logical, intent(in) :: dosfcflx
      integer, intent(in) :: iflux,pdef,pdefweno

      integer :: i,j,k
      real :: wbar
      double precision :: temd
      double precision, dimension(nk) :: sbar

      sfr = 0.0
      sfs = 0.0
      sfd = 0.0

      ! baseline algorithm:
      do k=2,nk
      do j=1,nj
      do i=1,ni
        dum3(i,j,k) = (c1(i,j,k)*s(i,j,k-1)+c2(i,j,k)*s(i,j,k))
        dum4(i,j,k) = dum3(i,j,k)
      enddo
      enddo
      enddo

    IF( advwenos.ge.1 )THEN

      if(     weno_order.eq.5 )then
        call vinterp_weno5(  1 ,ni,nj,nk,c1,c2,w3d,dum3,  s ,pdef,pdefweno,weps)
        call vinterp_flx6(   1 ,ni,nj,nk,c1,c2,w3d,dum4,  s )
      endif

    ELSE

        !buh3
      if(     vadvordrs.eq.5 )then
        call vinterp_flx5(   1 ,ni,nj,nk  ,c1,c2,w3d,dum3, s )
        call vinterp_flx6(   1 ,ni,nj,nk  ,c1,c2,w3d,dum4, s )
      elseif( vadvordrs.eq.6 )then
        call vinterp_flx6(   1 ,ni,nj,nk  ,c1,c2,w3d,dum3, s )
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum4(i,j,k) = dum3(i,j,k)
        enddo
        enddo
        enddo
      endif

    ENDIF

  !----------------------

    sbar = 0.0

    do k=2,nk
    do j=1,nj
    do i=1,ni
      sbar(k) = sbar(k)+dum3(i,j,k)
    enddo
    enddo
    enddo
        !buh4

    call MPI_ALLREDUCE(MPI_IN_PLACE,sbar(2),(nk-1),MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

    temd = 1.0d0/dble(nx*ny)

    do k=2,nk
      sbar(k)  = sbar(k)*temd
    enddo

  !----------------------

      !$omp parallel do default(shared)   &
      !$omp private(i,j,k)
      do k=2,nk
        do j=1,nj
        do i=1,ni

          sfr(k) = sfr(k) + w3d(i,j,k)*(dum4(i,j,k)-sbar(k))
          sfd(k) = sfd(k) + w3d(i,j,k)*(dum3(i,j,k)-dum4(i,j,k))
        !buh5
        enddo
        enddo
        if( cm1setup.ge.1 .or. ipbl.eq.2 .or. cm1setup.eq.3 )then
          do j=1,nj
          do i=1,ni
            sfs(k) = sfs(k) - khv(i,j,k)*(s(i,j,k)-s(i,j,k-1))*rdz*mf(i,j,k)
          enddo
          enddo
        else
          sfs(k) = 0.0
        endif
      enddo

      !-----------------------------
      ! 171122:  boundary conditions

      IF( cm1setup.eq.1 .or. cm1setup.eq.2 )THEN

        sfcfl:  &
        IF( iflux.eq.1 .and. dosfcflx )THEN

          do j=1,nj
          do i=1,ni
            sfs(1) = sfs(1) + sflux(i,j)
          enddo
          enddo

        ELSE  sfcfl

          IF( bcturbs.eq.1 )THEN

            sfs(1) = 0.0
            sfs(nk+1) = 0.0

          ELSEIF( bcturbs.eq.2 )THEN

            sfs(1) = sfs(2)
            sfs(nk+1) = sfs(nk)

          ENDIF

        ENDIF  sfcfl

      ELSEIF( cm1setup.eq.3 )THEN

          if(bc_temp.eq.1)then
            ! specified theta at boundary

            do j=1,nj
            do i=1,ni
              sfs(1) = sfs(1)-(viscosity/pr_num)*2.0*(savg(1)-ptc_bot)*rdz*mf(1,1,1)
              sfs(nk+1) = sfs(nk+1)-(viscosity/pr_num)*2.0*(ptc_top-savg(nk))*rdz*mf(1,1,nk+1)
            enddo
            enddo

          elseif(bc_temp.eq.2)then
            ! specified flux at boundary

            do j=1,nj
            do i=1,ni
              sfs(1) = sfs(1) + (viscosity/pr_num)*ptc_bot
              sfs(nk+1) = sfs(nk+1) + (viscosity/pr_num)*ptc_top
            enddo
            enddo

          endif

      ENDIF

      call MPI_ALLREDUCE(MPI_IN_PLACE,sfr(1) ,nk+1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,sfs(1) ,nk+1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
      call MPI_ALLREDUCE(MPI_IN_PLACE,sfd(1) ,nk+1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

      temd = 1.0d0/dble(nx*ny)

      !$omp parallel do default(shared)   &
      !$omp private(k)
      do k=1,nk+1
        sfr(k)  = sfr(k)*temd
        sfs(k)  = sfs(k)*temd
        sfd(k)  = sfd(k)*temd
      enddo

      end subroutine scalar_flux


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine getwstar(zf,thv0,rth0s,sfr,sfs,sfd,thfavg,qvfavg,wstar,fbmin,zfbmin)
      use input
      use constants
      implicit none

      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: zf
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: thv0
      real, intent(in), dimension(ib:ie,jb:je) :: rth0s
      double precision, intent(in), dimension(nk+1) :: sfr,sfs,sfd
      double precision, intent(in)    :: thfavg,qvfavg
      double precision, intent(inout) :: wstar,fbmin,zfbmin

      integer :: k
      real :: fb1,fb2

        wstar = 0.0
        fbmin = 1.0e30
        zfbmin = 0.0

        do k=1,nk
          if( k.eq.1 )then
            fb1 = g*( thfavg*rth0s(1,1) + repsm1*qvfavg )
          else
            fb1 = (sfr(k  )+sfs(k  )+sfd(k  ))*g/(0.5*(thv0(1,1,k)+thv0(1,1,k-1)))
          endif
          if( k.eq.nk )then
            fb2 = 0.0
          else
            fb2 = (sfr(k+1)+sfs(k+1)+sfd(k+1))*g/(0.5*(thv0(1,1,k)+thv0(1,1,k+1)))
          endif

          wstar = wstar + (zf(1,1,k+1)-zf(1,1,k))*0.5*(fb1+fb2)

          if( fb1.lt.fbmin )then
            fbmin = fb1
            zfbmin = zf(1,1,k)
          endif

        enddo

        wstar = 2.5*(max(0.0d0,wstar)**(1.0/3.0))

      end subroutine getwstar


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    subroutine getavg2d(s2d,savg2d)
    use input
    use mpi
    implicit none

    real, intent(in), dimension(ib:ie,jb:je) :: s2d
    double precision, intent(inout) :: savg2d

    integer :: i,j

    savg2d = 0.0

    do j=1,nj
    do i=1,ni
      savg2d = savg2d+s2d(i,j)
    enddo
    enddo

    call MPI_ALLREDUCE(MPI_IN_PLACE,savg2d,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

    savg2d = savg2d/dble(nx*ny)
   
    end subroutine getavg2d


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    subroutine getavg3d(s,savg,nkm)
    use input
    use mpi
    implicit none

    real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: s
    double precision, dimension(nk+1) :: savg
    integer, intent(in), optional :: nkm

    integer :: i,j,k,k2
    double precision :: temd

    savg = 0.0

    k2 = nk

    IF( present(nkm) )THEN
      k2 = min(nkm,nk+1)
    ENDIF

    do k=1,k2
      do j=1,nj
      do i=1,ni
        savg(k) = savg(k)+s(i,j,k)
      enddo
      enddo
    enddo

    call MPI_ALLREDUCE(MPI_IN_PLACE,savg(1),k2,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)

    temd = 1.0d0/dble(nx*ny)
    do k=1,k2
      savg(k) = savg(k)*temd
    enddo
   
    end subroutine getavg3d


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    subroutine getmax(s,savg,nkm)
    use input
    use mpi
    implicit none

    real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: s
    double precision, dimension(nk+1) :: savg
    integer, intent(in), optional :: nkm

    integer :: i,j,k,k2
    double precision :: temd

    savg = -1.0e30

    k2 = nk

    IF( present(nkm) )THEN
      k2 = min(nkm,nk+1)
    ENDIF

    do k=1,k2
      do j=1,nj
      do i=1,ni
        savg(k) = max(savg(k),s(i,j,k))
      enddo
      enddo
    enddo

    call MPI_ALLREDUCE(MPI_IN_PLACE,savg(1),k2,MPI_DOUBLE_PRECISION,MPI_MAX,MPI_COMM_WORLD,ierr)

    end subroutine getmax


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    subroutine getmin(s,savg,nkm)
    use input
    use mpi
    implicit none

    real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: s
    double precision, dimension(nk+1) :: savg
    integer, intent(in), optional :: nkm

    integer :: i,j,k,k2
    double precision :: temd

    savg = 1.0e30

    k2 = nk

    IF( present(nkm) )THEN
      k2 = min(nkm,nk+1)
    ENDIF

    do k=1,k2
      do j=1,nj
      do i=1,ni
        savg(k) = min(savg(k),s(i,j,k))
      enddo
      enddo
    enddo

    call MPI_ALLREDUCE(MPI_IN_PLACE,savg(1),k2,MPI_DOUBLE_PRECISION,MPI_MIN,MPI_COMM_WORLD,ierr)

    end subroutine getmin


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    subroutine write2d(savg2d,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
    use input
    implicit none

    double precision, intent(in) :: savg2d
    integer, intent(inout) :: trecs,trecw
    integer, intent(in) :: nvar
    character(len=80), intent(in), dimension(varmax) :: varname,vardesc,varunit
    character(len=1),  dimension(varmax) :: vargrid
      
    if( myid.eq.0 )then

      print *,nvar,trim(varname(nvar))

      ! grads-format file:

        ! note:  all 2d vars go into both scalar and w output files

        write(fnums,rec=trecs) sngl(savg2d)
        trecs = trecs+1

        write(fnumw,rec=trecw) sngl(savg2d)
        trecw = trecw+1

    endif

    end subroutine write2d


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    subroutine write3d(savg,trecs,trecw,vargrid,nvar,varname,vardesc,varunit)
    use input
    implicit none

    double precision, intent(in), dimension(nk+1) :: savg
    integer, intent(inout) :: trecs,trecw
    integer, intent(in) :: nvar
    character(len=80), intent(in), dimension(varmax) :: varname,vardesc,varunit
    character(len=1),  dimension(varmax) :: vargrid

    integer :: k
      
    if( myid.eq.0 )then

      print *,nvar,vargrid(nvar),' ',trim(varname(nvar))

      ! grads-format file:

      if( vargrid(nvar).eq.'s' )then
        do k=1,nk
          write(fnums,rec=trecs) sngl(savg(k))
          trecs = trecs+1
        enddo
      elseif( vargrid(nvar).eq.'w' )then
        do k=1,nk+1
          write(fnumw,rec=trecw) sngl(savg(k))
          trecw = trecw+1
        enddo
      else
        print *,' 67832 '
        call stopcm1
      endif

    endif

    end subroutine write3d


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

  END MODULE turbdiag_module
