/*============================================================================
* t@C¼ : XxcsoQtApTaxRateVOImpl
* Tvà¾   : ¼¥Å¦æ¾pr[NX
* o[W : 1.2
*============================================================================
* C³ð
* út       Ver. SÒ       C³àe
* ---------- ---- ------------ ----------------------------------------------
* 2011-05-17 1.0  SCSË¶aK  VKì¬
* 2013-08-20 1.1  SCSKìOç yE_{Ò®_10884zÁïÅÅÎ
* 2019-06-11 1.2  SCSK¢¼÷ yE_{Ò®_15472zy¸Å¦Î
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
// 2013-08-20 Ver1.1 [E_{Ò®_10884] Add Start
import oracle.jbo.domain.Date;
// 2013-08-20 Ver1.1 [E_{Ò®_10884] Add End
/*******************************************************************************
 * ¼¥Å¦æ¾Ìr[NXÅ·B
 * @author  SCSË¶aK
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQtApTaxRateVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQtApTaxRateVOImpl()
  {
  }
// 2013-08-20 Ver1.1 [E_{Ò®_10884] Add Start
  /*****************************************************************************
   * r[EIuWFNgÌú»ðs¢Ü·B
   * @param getDate ÁïÅæ¾îú
   * @param InventoryItemCode iÚR[h
   *****************************************************************************
   */
  public void initQuery(
    Date getDate
// 2019-06-11 Ver1.2 [E_{Ò®_15472] Add Start
  , String InventoryItemCode
// 2019-06-11 Ver1.2 [E_{Ò®_15472] Add End
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, getDate);
// 2019-06-11 Ver1.2 [E_{Ò®_15472] Add Start
    setWhereClauseParam(1, getDate);
    setWhereClauseParam(2, getDate);
    setWhereClauseParam(3, InventoryItemCode);
    setWhereClauseParam(4, getDate);
    setWhereClauseParam(5, getDate);
    setWhereClauseParam(6, getDate);
// 2019-06-11 Ver1.2 [E_{Ò®_15472] Add End

    executeQuery();

  }
// 2013-08-20 Ver1.1 [E_{Ò®_10884] Add End
}