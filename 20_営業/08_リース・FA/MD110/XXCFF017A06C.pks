CREATE OR REPLACE PACKAGE APPS.XXCFF017A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A06C (spec)
 * Description      : ���Y���Z����������X�g
 * MD.050           : ���Y���Z����������X�g (MD050_CFF_017A06)
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
 *  2014/06/17    1.0   T.Kobori         main�V�K�쐬
 *  2014/07/04    1.1   T.Kobori         ���ڒǉ�  1.�d����R�[�h
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2      -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2      -- �G���[�R�[�h     #�Œ�#
   ,iv_asset_number                 IN     VARCHAR2      -- 1.���Y�ԍ�
   ,iv_object_code                  IN     VARCHAR2      -- 2.�����R�[�h
   ,iv_segment1                     IN     VARCHAR2      -- 3.��ЃR�[�h
 -- 2014/07/04 ADD START
   ,iv_vendor_code                  IN     VARCHAR2      -- 10.�d����R�[�h
 -- 2014/07/04 ADD END
   ,iv_description                  IN     VARCHAR2      -- 4.�E�v
   ,iv_date_placed_in_service_from  IN     VARCHAR2      -- 5.���Ƌ��p�� FROM
   ,iv_date_placed_in_service_to    IN     VARCHAR2      -- 6.���Ƌ��p�� TO
   ,iv_original_cost_from           IN     VARCHAR2      -- 7.�擾���i FROM
   ,iv_original_cost_to             IN     VARCHAR2      -- 8.�擾���i TO
   ,iv_segment3                     IN     VARCHAR2      -- 9.���Y����
  );
END XXCFF017A06C;
/
