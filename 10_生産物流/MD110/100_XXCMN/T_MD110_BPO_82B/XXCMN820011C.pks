CREATE OR REPLACE PACKAGE xxcmn820011c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : XXCMN820011(spec)
 * Description      : �������ٕ\�쐬
 * MD.050/070       : �W�������}�X�^Issue1.0(T_MD050_BPO_820)
 *                    �������ٕ\�쐬Issue1.0(T_MD070_BPO_82B/T_MD070_BPO_82C)
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/20    1.0   Masayuki Ikeda   �V�K�쐬
 *  2008/12/18    1.1   Akiyoshi Shiina  �q�R���J�����g���N��������I��
 *
 *****************************************************************************************/
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�����[�^�D�\�`��
  rep_type_item       CONSTANT VARCHAR2(20) := '1' ;      -- �i�ڕʎ�����
  rep_type_vend       CONSTANT VARCHAR2(20) := '2' ;      -- �����ʕi�ڕ�
--
  -- �p�����[�^�D�o�͌`��
  out_type_dtl        CONSTANT VARCHAR2(20) := '1' ;      -- ����
  out_type_sum        CONSTANT VARCHAR2(20) := '2' ;      -- ���v
--
  -- �p�����[�^�D�����R�[�h
  dept_code_all       CONSTANT VARCHAR2(20) := 'ZZZZ' ;   -- �������ʂȂ�
--
  -- �v���O�������i�R���J�����g�E�e���v���[�g�j
  program_id_01       CONSTANT VARCHAR2(20) := 'XXCMN820021' ;    -- ���ׁF����ʕi�ڕ�
  program_id_02       CONSTANT VARCHAR2(20) := 'XXCMN820022' ;    -- ���v�F����ʕi�ڕ�
  program_id_03       CONSTANT VARCHAR2(20) := 'XXCMN820023' ;    -- ���ׁF�i�ڕ�
  program_id_04       CONSTANT VARCHAR2(20) := 'XXCMN820024' ;    -- ���v�F�i�ڕ�
  program_id_05       CONSTANT VARCHAR2(20) := 'XXCMN820025' ;    -- ���ׁF����ʎ�����
  program_id_06       CONSTANT VARCHAR2(20) := 'XXCMN820026' ;    -- ���v�F����ʎ�����
  program_id_07       CONSTANT VARCHAR2(20) := 'XXCMN820027' ;    -- ���ׁF������
  program_id_08       CONSTANT VARCHAR2(20) := 'XXCMN820028' ;    -- ���v�F������
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         --   �G���[�R�[�h
     ,iv_report_type        IN     VARCHAR2         --   01 : �\�`��
     ,iv_output_type        IN     VARCHAR2         --   02 : �o�͌`��
     ,iv_fiscal_ym          IN     VARCHAR2         --   03 : �Ώ۔N��
     ,iv_prod_div           IN     VARCHAR2         --   04 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         --   05 : �i�ڋ敪
     ,iv_dept_code          IN     VARCHAR2         --   06 : ��������
     ,iv_crowd_code_01      IN     VARCHAR2         --   07 : �Q�R�[�h�P
     ,iv_crowd_code_02      IN     VARCHAR2         --   08 : �Q�R�[�h�Q
     ,iv_crowd_code_03      IN     VARCHAR2         --   09 : �Q�R�[�h�R
     ,iv_item_code_01       IN     VARCHAR2         --   10 : �i�ڃR�[�h�P
     ,iv_item_code_02       IN     VARCHAR2         --   11 : �i�ڃR�[�h�Q
     ,iv_item_code_03       IN     VARCHAR2         --   12 : �i�ڃR�[�h�R
     ,iv_item_code_04       IN     VARCHAR2         --   13 : �i�ڃR�[�h�S
     ,iv_item_code_05       IN     VARCHAR2         --   14 : �i�ڃR�[�h�T
     ,iv_vendor_id_01       IN     VARCHAR2         --   15 : �����h�c�P
     ,iv_vendor_id_02       IN     VARCHAR2         --   16 : �����h�c�Q
     ,iv_vendor_id_03       IN     VARCHAR2         --   17 : �����h�c�R
     ,iv_vendor_id_04       IN     VARCHAR2         --   18 : �����h�c�S
     ,iv_vendor_id_05       IN     VARCHAR2         --   19 : �����h�c�T
    ) ;
END xxcmn820011c;
/
