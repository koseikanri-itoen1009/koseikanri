package itoen.oracle.apps.xxwip.xxwip200002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*============================================================================
* �t�@�C���� : XxwipBatchHeaderVOImpl
* �T�v����   : ���Y�o�b�`�w�b�_�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-09 1.0  ��r���     �V�K�쐬
*============================================================================
*/
public class XxwipBatchHeaderVOImpl extends OAViewObjectImpl  
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipBatchHeaderVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchBatchId - �����L�[
   ****************************************************************************/
  public void initQuery(String searchBatchId)
  {
    setWhereClauseParam(0, searchBatchId);
    executeQuery();
  }
}