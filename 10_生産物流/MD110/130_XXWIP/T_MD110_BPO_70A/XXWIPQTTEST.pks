CREATE OR REPLACE PACKAGE XXWIPQTTEST
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : XXWIPQTTEST(spec)
 * Description      : xxwip_common_pkg_test.make_qt_inspection�e�X�g�p�R���J�����g
 * MD.050           : -
 * MD.070           : -
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2007/12/03     1.0   H.Itou            �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_division          IN  VARCHAR2, -- IN  1.�敪         �K�{�i1:���Y 2:���� 3:���b�g��� 4:�O���o���� 5:�r�������j
    iv_disposal_div      IN  VARCHAR2, -- IN  2.�����敪     �K�{�i1:�ǉ� 2:�X�V 3:�폜�j
    iv_lot_id            IN  VARCHAR2, -- IN  3.���b�gID     �K�{
    iv_item_id           IN  VARCHAR2, -- IN  4.�i��ID       �K�{
    iv_qt_object         IN  VARCHAR2, -- IN  5.�Ώې�       �敪:5�̂ݕK�{�i1:�r���i�� 2:���Y���P 3:���Y���Q 4:���Y���R�j
    iv_batch_id          IN  VARCHAR2, -- IN  6.���Y�o�b�`ID �敪:1�̂ݕK�{
    iv_batch_po_id       IN  VARCHAR2, -- IN  7.���הԍ�     �敪:2�̂ݕK�{
    iv_qty               IN  VARCHAR2, -- IN  8.����         �敪:2�̂ݕK�{
    iv_prod_dely_date    IN  VARCHAR2, -- IN  9.�[����       �敪:2�̂ݕK�{
    iv_vendor_line       IN  VARCHAR2, -- IN 10.�d����R�[�h �敪:2�̂ݕK�{
    iv_qt_inspect_req_no IN  VARCHAR2  -- IN 11.�����˗�No   �����敪:2�A3�̂ݕK�{
  );
END XXWIPQTTEST;
/
