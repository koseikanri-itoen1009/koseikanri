/*============================================================================
* �t�@�C���� : XxcsoSpDecisionVendorCheckVOImpl
* �T�v����   : ���ꑗ�t�於���݊m�F�p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * ���ꑗ�t�悪���݂��邩�ǂ������m�F���邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionVendorCheckVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionVendorCheckVOImpl()
  {
  }


  public void initQuery(
    String vendorName
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, vendorName);

    executeQuery();
  }
}