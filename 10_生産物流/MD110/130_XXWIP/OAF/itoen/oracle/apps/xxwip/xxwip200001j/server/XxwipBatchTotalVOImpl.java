package itoen.oracle.apps.xxwip.xxwip200001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*============================================================================
* �t�@�C���� : XxwipBatchTotalVOImpl
* �T�v����   : ���Y���v�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-29 1.0  ��r���     �V�K�쐬
*============================================================================
*/

public class XxwipBatchTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipBatchTotalVOImpl()
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