/*============================================================================
* �t�@�C���� : XxcsoContractOtherCustFullVOImpl
* �T�v����   : �_���ȊO���擾�r���[�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2015-02-021.0  SCSK�R���đ� �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �_���ȊO���擾�r���[�I�u�W�F�N�g�N���X
 * @author  SCSK�R���đ�
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractOtherCustFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractOtherCustFullVOImpl()
  {
  }

  /*****************************************************************************
   * �r���[�E�I�u�W�F�N�g�̏�����
   * @param contractOtherCustsId �_���ȊOID
   *****************************************************************************
   */
  public void initQuery(
    Number contractOtherCustsId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, contractOtherCustsId);

    executeQuery();
  }
}