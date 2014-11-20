/*============================================================================
* �t�@�C���� : XxwipReInvestLotVOImpl
* �T�v����   : �ō����b�g���r���[�I�u�W�F�N�g
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-25 1.0  ��r���     �V�K�쐬
* 2008-09-10 1.1  ��r���     �����e�X�g�w�E�Ή�No30
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
/***************************************************************************
 * �ō����b�g���r���[�I�u�W�F�N�g�N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.1
 ***************************************************************************
 */
public class XxwipReInvestLotVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipReInvestLotVOImpl()
  {
  }
  /*****************************************************************************
   * �ō������擾SQL�����s���܂�
   * @param mtlDtlId - ���Y�����ڍ�ID
   ****************************************************************************/
  public void initQuery(String mtlDtlId) 
  {
    if (!XxcmnUtility.isBlankOrNull(mtlDtlId))
    {
      setWhereClauseParams(null); // Always reset
      setWhereClauseParam(0, mtlDtlId);
// 2008-09-10 v1.1 D.Nihei Add Start
      setWhereClauseParam(1, mtlDtlId);
      setWhereClauseParam(2, mtlDtlId);
// 2008-09-10 v1.1 D.Nihei Add End
      executeQuery();
    }
  }
}