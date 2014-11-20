CREATE OR REPLACE PACKAGE APPS.XXCFF017A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A02C (spec)
 * Description      : ���̋@����CSV�o��
 * MD.050           : ���̋@����CSV�o�� (MD050_CFF_017A02)
 * Version          : 1.0
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
 *  2014/06/09    1.0   T.Kobori         main�V�K�쐬
 *  2014/07/09    1.1   T.Kobori         ���ڒǉ�  1.�d����R�[�h
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2      -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2      -- �G���[�R�[�h     #�Œ�#
   ,iv_search_type                  IN     VARCHAR2      -- 1.�����敪 
   ,iv_machine_type                 IN     VARCHAR2      -- 2.�@��敪
   ,iv_object_code                  IN     VARCHAR2      -- 3.�����R�[�h
   ,iv_object_status                IN     VARCHAR2      -- 4.�����X�e�[�^�X
   ,iv_department_code              IN     VARCHAR2      -- 5.�Ǘ�����
   ,iv_manufacturer_name            IN     VARCHAR2      -- 6.���[�J��
   ,iv_model                        IN     VARCHAR2      -- 7.�@��
   ,iv_dclr_place                   IN     VARCHAR2      -- 8.�\���n
   ,iv_date_placed_in_service_from  IN     VARCHAR2      -- 9.���Ƌ��p�� FROM
   ,iv_date_placed_in_service_to    IN     VARCHAR2      -- 10.���Ƌ��p�� TO
   ,iv_date_retired_from            IN     VARCHAR2      -- 11.�����p�� FROM
   ,iv_date_retired_to              IN     VARCHAR2      -- 12.�����p�� TO
   ,iv_process_type                 IN     VARCHAR2      -- 13.���������敪
   ,iv_process_date_from            IN     VARCHAR2      -- 14.���������� FROM
   ,iv_process_date_to              IN     VARCHAR2      -- 15.���������� TO
 -- 2014/07/09 ADD START
   ,iv_vendor_code                  IN     VARCHAR2      -- 16.�d����R�[�h
 -- 2014/07/09 ADD END
  );
END XXCFF017A02C;
/
