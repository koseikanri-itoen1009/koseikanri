CREATE OR REPLACE PACKAGE APPS.xxcso_rtn_rsrc_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_util_common_pkg(SPEC)
 * Description      : ���[�gNo/�S���c�ƈ��X�V�����֐�
 * MD.050/070       :
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  regist_route_no           P    -     ���[�gNo�o�^�֐�
 *  unregist_route_no         P    -     ���[�gNo�폜�֐�
 *  regist_resource_no        P    -     �S���c�ƈ��o�^�֐�
 *  unregist_resource_no      P    -     �S���c�ƈ��폜�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/08    1.0   H.Ogawa          �V�K�쐬
 *  2008/12/24    1.0   M.maruyama       �w�b�_�C��(Oracle�ł���SCS�ł�)
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
   /**********************************************************************************
   * Function Name    : regist_route_no
   * Description      : ���[�gNo�o�^�֐�
   ***********************************************************************************/
  PROCEDURE regist_route_no(
    iv_account_number            IN  VARCHAR2         -- �ڋq�R�[�h
   ,iv_route_no                  IN  VARCHAR2         -- ���[�gNo
   ,id_start_date                IN  DATE             -- �K�p�J�n��
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- �V�X�e�����b�Z�[�W
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- ��������('0':����, '1':�x��, '2':�G���[)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ���[�U�[���b�Z�[�W
  );
--
   /**********************************************************************************
   * Function Name    : unregist_route_no
   * Description      : ���[�gNo�폜�֐�
   ***********************************************************************************/
  PROCEDURE unregist_route_no(
    iv_account_number            IN  VARCHAR2         -- �ڋq�R�[�h
   ,iv_route_no                  IN  VARCHAR2         -- ���[�gNo
   ,id_start_date                IN  DATE             -- �K�p�J�n��
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- �V�X�e�����b�Z�[�W
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- ��������('0':����, '1':�x��, '2':�G���[)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ���[�U�[���b�Z�[�W
  );
--
   /**********************************************************************************
   * Function Name    : regist_resource_no
   * Description      : �S���c�ƈ��o�^�֐�
   ***********************************************************************************/
  PROCEDURE regist_resource_no(
    iv_account_number            IN  VARCHAR2         -- �ڋq�R�[�h
   ,iv_resource_no               IN  VARCHAR2         -- �S���c�ƈ��i�]�ƈ��R�[�h�j
   ,id_start_date                IN  DATE             -- �K�p�J�n��
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- �V�X�e�����b�Z�[�W
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- ��������('0':����, '1':�x��, '2':�G���[)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ���[�U�[���b�Z�[�W
  );
--
   /**********************************************************************************
   * Function Name    : unregist_resource_no
   * Description      : �S���c�ƈ��폜�֐�
   ***********************************************************************************/
  PROCEDURE unregist_resource_no(
    iv_account_number            IN  VARCHAR2         -- �ڋq�R�[�h
   ,iv_resource_no               IN  VARCHAR2         -- �S���c�ƈ��i�]�ƈ��R�[�h�j
   ,id_start_date                IN  DATE             -- �K�p�J�n��
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- �V�X�e�����b�Z�[�W
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- ��������('0':����, '1':�x��, '2':�G���[)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ���[�U�[���b�Z�[�W
  );
--
END xxcso_rtn_rsrc_pkg;
/
