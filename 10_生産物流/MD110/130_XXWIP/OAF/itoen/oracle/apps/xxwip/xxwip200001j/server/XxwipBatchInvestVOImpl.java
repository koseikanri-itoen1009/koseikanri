package itoen.oracle.apps.xxwip.xxwip200001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*============================================================================
* �t�@�C���� : XxwipBatchInvestVOImpl
* �T�v����   : ���Y���������r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-09 1.0  ��r���     �V�K�쐬
*============================================================================
*/
public class XxwipBatchInvestVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipBatchInvestVOImpl()
  {
  }
  /*****************************************************************************
   * VO�̏��������s���܂��B
   * @param searchBatchId - �����L�[
   ****************************************************************************/
  public void initQuery(String searchBatchId)
  {
    setWhereClauseParam(0, searchBatchId);
    setWhereClauseParam(1, searchBatchId);
    executeQuery();
  }
}