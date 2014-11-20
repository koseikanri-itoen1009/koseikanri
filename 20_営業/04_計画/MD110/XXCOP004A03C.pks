CREATE OR REPLACE PACKAGE XXCOP004A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A03C(spec)
 * Description      : ����v��W�v
 * MD.050           : ����v��W�v MD050_COP_004_A03
 * Version          : 1.2
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
 *  2008/11/03    1.0  SCS.Kikuchi       main�V�K�쐬
 *  2009/02/13    1.1  SCS.Kikuchi       �����e�X�g�d�l�ύX�i������QNo.008,009�j
 *  2009/04/07    1.2  SCS.Kikuchi       T1_0271�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf                        OUT VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
    ,retcode                       OUT VARCHAR2         --   �G���[�R�[�h     #�Œ�#
    ,iv_base_code                  IN  VARCHAR2         -- 1.���_
    ,iv_prod_class_code            IN  VARCHAR2         -- 2.���i�敪
    ,iv_results_collect_period_st  IN  VARCHAR2         -- 3.���ю��W���ԁi���j
    ,iv_results_collect_period_ed  IN  VARCHAR2         -- 4.���ю��W���ԁi���j
    ,iv_forecast_collect_period_st IN  VARCHAR2         -- 5.�v����W���ԁi���j
    ,iv_forecast_collect_period_ed IN  VARCHAR2         -- 6.�v����W���ԁi���j
   );

END XXCOP004A03C;
/
