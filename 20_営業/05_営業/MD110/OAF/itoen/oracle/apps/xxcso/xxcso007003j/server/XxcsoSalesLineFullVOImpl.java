/*============================================================================
* �t�@�C���� : XxcsoSalesLineFullVOImpl
* �T�v����   : ���k�����񖾍דo�^�^�X�V�p�r���[�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.Row;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

/*******************************************************************************
 * ���k�����񖾍׏���o�^�^�X�V���邽�߂̃r���[�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesLineFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesLineFullVOImpl()
  {
  }


  /*****************************************************************************
   * LOV�{�^���ɂ�郌�R�[�h�ǉ������ł��B
   * @see interface oracle.jbo.RowIterator.insertRowAtRangeIndex
   *****************************************************************************
   */
  public void insertRowAtRangeIndex(int index, Row row)
  {
    OAApplicationModule am = (OAApplicationModule)getApplicationModule();
    OADBTransaction txn = am.getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    last();
    next();
    super.insertRow(row);

    XxcsoUtils.debug(txn, "[END]");
  }
}