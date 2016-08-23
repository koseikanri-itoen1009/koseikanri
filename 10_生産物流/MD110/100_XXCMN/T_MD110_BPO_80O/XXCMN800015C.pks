CREATE OR REPLACE PACKAGE XXCMN800015C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCMN800015C(spec)
 * Description      : ���b�g����CSV�t�@�C���o�͂��A���[�N�t���[�`���ŘA�g���܂��B
 * MD.050           : ���b�g���C���^�t�F�[�X<T_MD050_BPO_801>
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
 *  2016/06/23    1.0   K.Kiriu          �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT VARCHAR2        -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                   OUT VARCHAR2        -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_item_code              IN  VARCHAR2        -- 1.�i�ڃR�[�h
   ,iv_item_div               IN  VARCHAR2        -- 2.�i�ڋ敪
   ,iv_lot_no                 IN  VARCHAR2        -- 3.���b�gNo
   ,iv_subinventory_code      IN  VARCHAR2        -- 4.�q�ɃR�[�h
   ,iv_effective_date         IN  VARCHAR2        -- 5.�L����
   ,iv_prod_div               IN  VARCHAR2        -- 6.���i�敪
  );
END XXCMN800015C;
/
