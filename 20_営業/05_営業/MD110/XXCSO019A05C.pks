create or replace PACKAGE XXCSO019A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A05C(spec)
 * Description      : �v���̔��s��ʂ���A�K�┄��v��Ǘ��\�𒠕[�ɏo�͂��܂��B
 * MD.050           : MD050_CSO_019_A05_�K�┄��v��Ǘ��\_Draft2.0A
 * Version          : 1.1
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 * get_gvm_type          ��ʁ^���̋@�^�l�b�擾
 * get_tgt_amt           ����v��擾
 * get_rslt_amt          ������ю擾
 * get_rslt_other_sales_amt  �����_�[�i��������ю擾
 * get_visit_sign        �K��L���擾
 * get_i_tgt_vis_num     �K��v��擾(��ʗp)
 * get_v_tgt_vis_num     �K��v��擾(���̋@�p)
 * get_i_rslt_vis_num    �K����ю擾(��ʗp)
 * get_v_rslt_vis_num    �K����ю擾(���̋@�p)
 * get_m_rslt_vis_num    �K����ю擾(MC�p)
 * get_e_rslt_vis_num    �K����ю擾(�L���K��p)
 * main                  �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05    1.0   Seirin.Kin        �V�K�쐬
 *  2009-05-19    1.1   Hiroshi.Ogawa     ��Q�ԍ��FT1_1033
 *
 *****************************************************************************************/
 --
/* 20090519_Ogawa_T1_1033 START*/
  -- �O���[�v���擾 �� xxcso_util_common_pkg�Ɉړ�
  FUNCTION get_group_name(
    iv_base_code         IN  VARCHAR2     -- ���_�R�[�h
   ,iv_group_number      IN  VARCHAR2     -- �O���[�v�ԍ�
   ,id_standard_date     IN  DATE         -- ���
  ) RETURN VARCHAR2;
--
  -- �K��\��񐔎擾 �� xxcso_route_common_pkg�Ɉړ�
  FUNCTION get_route_bit(
    iv_route_no          IN  VARCHAR2     -- ���[�gNo
   ,iv_year_month        IN  VARCHAR2     -- �N��
   ,in_day_index         IN  NUMBER       -- ��
  ) RETURN NUMBER;
--
  -- ��ʁ^���̋@�^�l�b�擾
  FUNCTION get_gvm_type(
    iv_customer_status   IN  VARCHAR2     -- �ڋq�X�e�[�^�X
   ,iv_business_low_type IN  VARCHAR2     -- �ƑԃR�[�h�i�����ށj
  ) RETURN VARCHAR2;
--
  -- ����v��擾
  FUNCTION get_tgt_amt(
    iv_base_code         IN  VARCHAR2     -- ���_�R�[�h
   ,iv_account_number    IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_year_month        IN  VARCHAR2     -- �N��
   ,in_day_index         IN  NUMBER       -- ��
  ) RETURN NUMBER;
--
  -- ������ю擾
  FUNCTION get_rslt_amt(
    iv_base_code         IN  VARCHAR2     -- ���_�R�[�h
   ,iv_account_number    IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_year_month        IN  VARCHAR2     -- �N��
   ,in_day_index         IN  NUMBER       -- ��
  ) RETURN NUMBER;
--
  -- �����_�[�i��������ю擾
  FUNCTION get_rslt_other_sales_amt(
    iv_base_code         IN  VARCHAR2     -- ���_�R�[�h
   ,iv_account_number    IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_year_month        IN  VARCHAR2     -- �N��
   ,in_day_index         IN  NUMBER       -- ��
  ) RETURN NUMBER;
--
  -- �K��L���擾
  FUNCTION get_visit_sign(
    iv_base_code         IN  VARCHAR2     -- ���_�R�[�h
   ,iv_account_number    IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_year_month        IN  VARCHAR2     -- �N��
   ,in_day_index         IN  NUMBER       -- ��
  ) RETURN VARCHAR2;
--
  -- �K��v��擾(��ʗp)
  FUNCTION get_i_tgt_vis_num(
    iv_base_code         IN  VARCHAR2     -- ���_�R�[�h
   ,iv_account_number    IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_year_month        IN  VARCHAR2     -- �N��
   ,in_day_index         IN  NUMBER       -- ��
  ) RETURN NUMBER;
--
  -- �K��v��擾(���̋@�p)
  FUNCTION get_v_tgt_vis_num(
    iv_base_code         IN  VARCHAR2     -- ���_�R�[�h
   ,iv_account_number    IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_year_month        IN  VARCHAR2     -- �N��
   ,in_day_index         IN  NUMBER       -- ��
  ) RETURN NUMBER;
--
  -- �K����ю擾(��ʗp)
  FUNCTION get_i_rslt_vis_num(
    iv_base_code         IN  VARCHAR2     -- ���_�R�[�h
   ,iv_account_number    IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_year_month        IN  VARCHAR2     -- �N��
   ,in_day_index         IN  NUMBER       -- ��
  ) RETURN NUMBER;
--
  -- �K����ю擾(���̋@�p)
  FUNCTION get_v_rslt_vis_num(
    iv_base_code         IN  VARCHAR2     -- ���_�R�[�h
   ,iv_account_number    IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_year_month        IN  VARCHAR2     -- �N��
   ,in_day_index         IN  NUMBER       -- ��
  ) RETURN NUMBER;
--
  -- �K����ю擾(MC�p)
  FUNCTION get_m_rslt_vis_num(
    iv_base_code         IN  VARCHAR2     -- ���_�R�[�h
   ,iv_account_number    IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_year_month        IN  VARCHAR2     -- �N��
   ,in_day_index         IN  NUMBER       -- ��
  ) RETURN NUMBER;
--
  -- �K����ю擾(�L���K��p)
  FUNCTION get_e_rslt_vis_num(
    iv_base_code         IN  VARCHAR2     -- ���_�R�[�h
   ,iv_account_number    IN  VARCHAR2     -- �ڋq�R�[�h
   ,iv_year_month        IN  VARCHAR2     -- �N��
   ,in_day_index         IN  NUMBER       -- ��
  ) RETURN NUMBER;
--
/* 20090519_Ogawa_T1_1033 END*/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode           OUT NOCOPY VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_year_month     IN         VARCHAR2          -- ��N��
   ,iv_report_type    IN         VARCHAR2          -- ���[���
   ,iv_base_code      IN         VARCHAR2          -- ���_�R�[�h
  );
END XXCSO019A05C;
/
