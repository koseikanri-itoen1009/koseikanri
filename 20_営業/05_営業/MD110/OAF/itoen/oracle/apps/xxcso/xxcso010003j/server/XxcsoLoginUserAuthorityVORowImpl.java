/*============================================================================
* �t�@�C���� : XxcsoLoginUserAuthorityVORowImpl
* �T�v����   : ���O�C�����[�U�[�����擾�r���[�s�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-28 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * ���O�C�����[�U�[�����擾�r���[�s�I�u�W�F�N�g�N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoLoginUserAuthorityVORowImpl extends OAViewRowImpl 
{











  protected static final int USERAUTHORITY = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoLoginUserAuthorityVORowImpl()
  {
  }






  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case USERAUTHORITY:
        return getUserAuthority();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UserAuthority
   */
  public String getUserAuthority()
  {
    return (String)getAttributeInternal(USERAUTHORITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UserAuthority
   */
  public void setUserAuthority(String value)
  {
    setAttributeInternal(USERAUTHORITY, value);
  }



}