package itoen.oracle.apps.xxwip.poplist.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*============================================================================
* �t�@�C���� : SlitVOImpl
* �T�v����   : �������|�b�v���X�g�r���[�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2007-11-19 1.0  ��r���     �V�K�쐬
*============================================================================
*/
public class SlitVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public SlitVOImpl()
  {
  }
  /*****************************************************************************
   * �������|�b�v���X�g�擾SQL�����s���܂�
   * @param routingId �H��ID
   ****************************************************************************/
  public void initQuery(String routingId) {
    setWhereClauseParams(null); // Always reset
    setWhereClauseParam(0, routingId);
    executeQuery();
  }
}